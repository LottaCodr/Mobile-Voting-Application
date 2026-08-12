import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFonts } from 'expo-font';
import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  Share,
  StatusBar,
  StyleSheet,
  Switch,
  useWindowDimensions,
  View,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  Badge,
  Button,
  Divider,
  IconButton,
  IconName,
  Panel,
  PreferencesContext,
  Sheet,
  Text,
  TextSizePreference,
  usePreferences,
} from '../src/ui/primitives';
import {
  Candidate,
  Election,
  elections,
  resultRows,
  updateItems,
} from '../src/data/demo';
import { submitBallot, supabase } from '../src/data/supabase';
import { colors, shadows } from '../src/theme/colors';

type Tab = 'Home' | 'Elections' | 'Results' | 'Updates' | 'Profile';
type BallotStage = 'closed' | 'intro' | 'contest' | 'review' | 'success';
type ChoiceMap = Record<string, string | null>;
type SheetName = 'help' | 'security' | 'how' | 'receipt' | 'election' | null;

const navItems: { tab: Tab; icon: IconName; activeIcon: IconName }[] = [
  { tab: 'Home', icon: 'home-outline', activeIcon: 'home' },
  { tab: 'Elections', icon: 'file-tray-full-outline', activeIcon: 'file-tray-full' },
  { tab: 'Results', icon: 'bar-chart-outline', activeIcon: 'bar-chart' },
  { tab: 'Updates', icon: 'notifications-outline', activeIcon: 'notifications' },
  { tab: 'Profile', icon: 'person-outline', activeIcon: 'person' },
];

const preferenceKey = 'civicvote.preview.preferences.v1';

export default function CivicVote() {
  const [fontsLoaded] = useFonts({
    Montserrat_400Regular: require('../fonts/Montserrat-Regular.ttf'),
    Montserrat_500Medium: require('../fonts/Montserrat-Medium.ttf'),
    Montserrat_600SemiBold: require('../fonts/Montserrat-SemiBold.ttf'),
    Montserrat_700Bold: require('../fonts/Montserrat-Bold.ttf'),
    Montserrat_800ExtraBold: require('../fonts/Montserrat-ExtraBold.ttf'),
  });
  const [textSize, setTextSize] = useState<TextSizePreference>('standard');
  const [highContrast, setHighContrast] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [preferencesLoaded, setPreferencesLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(preferenceKey)
      .then((stored) => {
        if (!stored) return;
        const parsed = JSON.parse(stored) as {
          textSize?: TextSizePreference;
          highContrast?: boolean;
          reduceMotion?: boolean;
        };
        if (parsed.textSize) setTextSize(parsed.textSize);
        if (typeof parsed.highContrast === 'boolean') setHighContrast(parsed.highContrast);
        if (typeof parsed.reduceMotion === 'boolean') setReduceMotion(parsed.reduceMotion);
      })
      .catch(() => undefined)
      .finally(() => setPreferencesLoaded(true));
  }, []);

  useEffect(() => {
    if (!preferencesLoaded) return;
    AsyncStorage.setItem(
      preferenceKey,
      JSON.stringify({ textSize, highContrast, reduceMotion }),
    ).catch(() => undefined);
  }, [highContrast, preferencesLoaded, reduceMotion, textSize]);

  if (!fontsLoaded) {
    return (
      <View style={styles.loadingScreen}>
        <ActivityIndicator color={colors.blue} size="large" />
      </View>
    );
  }

  return (
    <PreferencesContext.Provider value={{ textSize, highContrast, reduceMotion }}>
      <CivicVoteApp
        highContrast={highContrast}
        reduceMotion={reduceMotion}
        setHighContrast={setHighContrast}
        setReduceMotion={setReduceMotion}
        setTextSize={setTextSize}
        textSize={textSize}
      />
    </PreferencesContext.Provider>
  );
}

function CivicVoteApp({
  highContrast,
  reduceMotion,
  setHighContrast,
  setReduceMotion,
  setTextSize,
  textSize,
}: {
  highContrast: boolean;
  reduceMotion: boolean;
  setHighContrast: (value: boolean) => void;
  setReduceMotion: (value: boolean) => void;
  setTextSize: (value: TextSizePreference) => void;
  textSize: TextSizePreference;
}) {
  const { width } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const desktop = width >= 900;
  const [tab, setTab] = useState<Tab>('Home');
  const [stage, setStage] = useState<BallotStage>('closed');
  const [activeContest, setActiveContest] = useState(0);
  const [choices, setChoices] = useState<ChoiceMap>({});
  const [focusedCandidate, setFocusedCandidate] = useState<Candidate | null>(null);
  const [sheet, setSheet] = useState<SheetName>(null);
  const [selectedElection, setSelectedElection] = useState<Election>(elections[0]);
  const [reviewed, setReviewed] = useState(false);
  const [confirmCast, setConfirmCast] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [receipt, setReceipt] = useState<string | null>(null);
  const [submittedAt, setSubmittedAt] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [readUpdates, setReadUpdates] = useState<string[]>([]);

  const answeredCount = selectedElection.contests.filter((contest) =>
    Object.prototype.hasOwnProperty.call(choices, contest.id),
  ).length;
  const unreadCount = updateItems.filter(
    (item) => item.unread && !readUpdates.includes(item.id),
  ).length;

  const changeTab = (nextTab: Tab) => {
    setTab(nextTab);
    setStage('closed');
  };

  const beginElection = (election: Election) => {
    setSelectedElection(election);
    if (election.status === 'Open') {
      setStage(submitted ? 'success' : 'intro');
      return;
    }
    if (election.status === 'Completed') {
      setTab('Results');
      return;
    }
    setSheet('election');
  };

  const beginBallot = () => {
    setActiveContest(0);
    setReviewed(false);
    setSubmitError(null);
    setStage('contest');
  };

  const closeBallot = () => {
    if (stage === 'success') {
      setStage('closed');
      setTab('Home');
      return;
    }
    if (answeredCount > 0) {
      Alert.alert(
        'Save and leave ballot?',
        'Your draft stays only in this app session. It has not been submitted.',
        [
          { text: 'Keep voting', style: 'cancel' },
          { text: 'Save and leave', onPress: () => setStage('closed') },
        ],
      );
      return;
    }
    setStage('closed');
  };

  const chooseCandidate = (contestId: string, candidateId: string) => {
    setChoices((current) => ({ ...current, [contestId]: candidateId }));
  };

  const skipContest = () => {
    const contest = selectedElection.contests[activeContest];
    setChoices((current) => ({ ...current, [contest.id]: null }));
    if (activeContest === selectedElection.contests.length - 1) {
      setStage('review');
    } else {
      setActiveContest((current) => current + 1);
    }
  };

  const nextContest = () => {
    if (activeContest === selectedElection.contests.length - 1) {
      setStage('review');
    } else {
      setActiveContest((current) => current + 1);
    }
  };

  const editContest = (index: number) => {
    setActiveContest(index);
    setStage('contest');
  };

  const castBallot = async () => {
    setConfirmCast(false);
    setSubmitting(true);
    setSubmitError(null);
    try {
      let nextReceipt: string;
      let nextSubmittedAt: string;
      if (supabase) {
        const ballotChoices = Object.entries(choices)
          .filter((entry): entry is [string, string] => typeof entry[1] === 'string')
          .map(([contestId, candidateId]) => ({
            contest_id: contestId,
            candidate_id: candidateId,
          }));
        const result = await submitBallot(selectedElection.id, ballotChoices);
        nextReceipt = result.receipt_code;
        nextSubmittedAt = result.submitted_at;
      } else {
        await new Promise((resolve) => setTimeout(resolve, reduceMotion ? 250 : 1050));
        const token = Date.now().toString(36).toUpperCase().slice(-8);
        nextReceipt = `CV-${token.slice(0, 4)}-${token.slice(4)}`;
        nextSubmittedAt = new Date().toISOString();
      }
      setReceipt(nextReceipt);
      setSubmittedAt(nextSubmittedAt);
      setSubmitted(true);
      setChoices({});
      setStage('success');
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : 'We could not confirm submission. Check your ballot status before trying again.';
      setSubmitError(message);
    } finally {
      setSubmitting(false);
    }
  };

  const shareReceipt = async () => {
    if (!receipt) return;
    await Share.share({
      message: `CivicVote submission receipt\n${receipt}\n${selectedElection.shortTitle}\nThis receipt confirms submission only and never shows ballot selections.`,
      title: 'CivicVote submission receipt',
    });
  };

  const screen = (() => {
    if (tab === 'Home') {
      return (
        <HomeScreen
          answeredCount={answeredCount}
          onHelp={() => setSheet('help')}
          onOpenBallot={() => beginElection(elections[0])}
          onOpenElection={(election) => beginElection(election)}
          onSecurity={() => setSheet('security')}
          submitted={submitted}
          totalContests={elections[0].contests.length}
        />
      );
    }
    if (tab === 'Elections') {
      return <ElectionsScreen onOpenElection={beginElection} submitted={submitted} />;
    }
    if (tab === 'Results') return <ResultsScreen />;
    if (tab === 'Updates') {
      return (
        <UpdatesScreen
          readUpdates={readUpdates}
          setReadUpdates={setReadUpdates}
        />
      );
    }
    return (
      <ProfileScreen
        highContrast={highContrast}
        onHelp={() => setSheet('help')}
        onSecurity={() => setSheet('security')}
        reduceMotion={reduceMotion}
        setHighContrast={setHighContrast}
        setReduceMotion={setReduceMotion}
        setTextSize={setTextSize}
        textSize={textSize}
      />
    );
  })();

  const ballotExperience =
    stage === 'intro' ? (
      <BallotIntro
        answeredCount={answeredCount}
        election={selectedElection}
        onBegin={beginBallot}
        onClose={closeBallot}
        onHow={() => setSheet('how')}
      />
    ) : stage === 'contest' ? (
      <ContestScreen
        choices={choices}
        contestIndex={activeContest}
        election={selectedElection}
        onBack={() => {
          if (activeContest === 0) setStage('intro');
          else setActiveContest((current) => current - 1);
        }}
        onChoose={chooseCandidate}
        onClose={closeBallot}
        onDetails={setFocusedCandidate}
        onNext={nextContest}
        onSkip={skipContest}
      />
    ) : stage === 'review' ? (
      <ReviewScreen
        choices={choices}
        election={selectedElection}
        error={submitError}
        onBack={() => {
          setActiveContest(selectedElection.contests.length - 1);
          setStage('contest');
        }}
        onCast={() => setConfirmCast(true)}
        onClose={closeBallot}
        onEdit={editContest}
        reviewed={reviewed}
        setReviewed={setReviewed}
        submitting={submitting}
      />
    ) : (
      <ReceiptScreen
        election={selectedElection}
        onDone={closeBallot}
        onExplain={() => setSheet('receipt')}
        onShare={shareReceipt}
        receipt={receipt}
        submittedAt={submittedAt}
      />
    );

  return (
    <SafeAreaView
      edges={['top', 'left', 'right']}
      style={[styles.safe, highContrast && styles.safeHighContrast]}>
      <StatusBar barStyle="dark-content" backgroundColor={colors.surface} />
      {stage !== 'closed' ? (
        ballotExperience
      ) : desktop ? (
        <View style={styles.desktopShell}>
          <SideNavigation
            onChange={changeTab}
            selected={tab}
            unreadCount={unreadCount}
          />
          <View style={styles.desktopMain}>
            <AppHeader onHelp={() => setSheet('help')} />
            <View style={styles.main}>{screen}</View>
          </View>
        </View>
      ) : (
        <>
          <AppHeader onHelp={() => setSheet('help')} />
          <View style={styles.main}>{screen}</View>
          <BottomNavigation
            bottomInset={insets.bottom}
            onChange={changeTab}
            selected={tab}
            unreadCount={unreadCount}
          />
        </>
      )}

      <CandidateSheet candidate={focusedCandidate} onClose={() => setFocusedCandidate(null)} />
      <InformationSheets
        election={selectedElection}
        onClose={() => setSheet(null)}
        sheet={sheet}
      />
      <CastConfirmation
        onCancel={() => setConfirmCast(false)}
        onConfirm={castBallot}
        visible={confirmCast}
      />
    </SafeAreaView>
  );
}

function AppHeader({ onHelp }: { onHelp: () => void }) {
  return (
    <View style={styles.appHeader}>
      <Brand />
      <View style={styles.headerActions}>
        <View style={styles.previewLabel}>
          <View style={styles.previewDot} />
          <Text style={styles.previewText}>Product preview</Text>
        </View>
        <IconButton icon="help-circle-outline" label="Help and support" onPress={onHelp} />
      </View>
    </View>
  );
}

function Brand({ inverse = false }: { inverse?: boolean }) {
  return (
    <View accessibilityLabel="CivicVote" accessibilityRole="header" style={styles.brandRow}>
      <View style={[styles.logoMark, inverse && styles.logoMarkInverse]}>
        <Ionicons name="checkmark" size={20} color={inverse ? colors.blue : colors.surface} />
      </View>
      <Text style={[styles.brandText, inverse && styles.brandTextInverse]}>CivicVote</Text>
    </View>
  );
}

function SideNavigation({
  onChange,
  selected,
  unreadCount,
}: {
  onChange: (tab: Tab) => void;
  selected: Tab;
  unreadCount: number;
}) {
  return (
    <View style={styles.sideNav}>
      <Brand inverse />
      <Text style={styles.sideContext}>VOTER PORTAL</Text>
      <View style={styles.sideNavItems}>
        {navItems.map((item) => {
          const active = selected === item.tab;
          return (
            <Pressable
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              key={item.tab}
              onPress={() => onChange(item.tab)}
              style={({ pressed }) => [
                styles.sideNavItem,
                active && styles.sideNavItemActive,
                pressed && styles.pressOpacity,
              ]}>
              <Ionicons
                name={active ? item.activeIcon : item.icon}
                size={21}
                color={active ? colors.navyDeep : '#AFC1DD'}
              />
              <Text style={[styles.sideNavLabel, active && styles.sideNavLabelActive]}>
                {item.tab}
              </Text>
              {item.tab === 'Updates' && unreadCount > 0 ? (
                <View style={styles.navCount}>
                  <Text style={styles.navCountText}>{unreadCount}</Text>
                </View>
              ) : null}
            </Pressable>
          );
        })}
      </View>
      <View style={styles.sideVerified}>
        <Ionicons name="shield-checkmark" size={19} color="#8CE0C5" />
        <View style={styles.flex}>
          <Text style={styles.sideVerifiedTitle}>Verified voter</Text>
          <Text style={styles.sideVerifiedBody}>Riverside Borough</Text>
        </View>
      </View>
    </View>
  );
}

function BottomNavigation({
  bottomInset,
  onChange,
  selected,
  unreadCount,
}: {
  bottomInset: number;
  onChange: (tab: Tab) => void;
  selected: Tab;
  unreadCount: number;
}) {
  return (
    <View style={[styles.bottomNav, { paddingBottom: Math.max(bottomInset, 8) }]}>
      {navItems.map((item) => {
        const active = selected === item.tab;
        return (
          <Pressable
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            key={item.tab}
            onPress={() => onChange(item.tab)}
            style={({ pressed }) => [styles.bottomNavItem, pressed && styles.pressOpacity]}>
            <View style={[styles.navIconWrap, active && styles.navIconWrapActive]}>
              <Ionicons
                name={active ? item.activeIcon : item.icon}
                size={21}
                color={active ? colors.blueDark : colors.muted}
              />
              {item.tab === 'Updates' && unreadCount > 0 ? (
                <View style={styles.unreadDot} />
              ) : null}
            </View>
            <Text style={[styles.bottomNavText, active && styles.bottomNavTextActive]}>
              {item.tab}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function ScreenScroll({ children }: { children: React.ReactNode }) {
  return (
    <ScrollView
      contentContainerStyle={styles.screenContent}
      keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}>
      {children}
    </ScrollView>
  );
}

function ScreenHeading({
  eyebrow,
  title,
  body,
}: {
  eyebrow?: string;
  title: string;
  body?: string;
}) {
  return (
    <View style={styles.screenHeading}>
      {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
      <Text accessibilityRole="header" style={styles.h1}>
        {title}
      </Text>
      {body ? <Text style={styles.intro}>{body}</Text> : null}
    </View>
  );
}

function HomeScreen({
  answeredCount,
  onHelp,
  onOpenBallot,
  onOpenElection,
  onSecurity,
  submitted,
  totalContests,
}: {
  answeredCount: number;
  onHelp: () => void;
  onOpenBallot: () => void;
  onOpenElection: (election: Election) => void;
  onSecurity: () => void;
  submitted: boolean;
  totalContests: number;
}) {
  const primaryLabel = submitted
    ? 'View submission receipt'
    : answeredCount > 0
      ? 'Continue your ballot'
      : 'Start your ballot';
  return (
    <ScreenScroll>
      <View style={styles.homeGreeting}>
        <View style={styles.flex}>
          <Text style={styles.dateLabel}>WEDNESDAY, 12 AUGUST</Text>
          <Text accessibilityRole="header" style={styles.homeTitle}>
            Good afternoon, Maya.
          </Text>
          <Text style={styles.homeSubtitle}>Here’s what needs your attention.</Text>
        </View>
        <View accessibilityLabel="Profile avatar for Maya Chen" style={styles.profileMini}>
          <Text style={styles.profileMiniText}>MC</Text>
        </View>
      </View>

      <View style={styles.heroCard}>
        <View style={styles.heroOrbOne} />
        <View style={styles.heroOrbTwo} />
        <View style={styles.heroTopRow}>
          <Badge
            icon={submitted ? 'checkmark-circle' : 'time'}
            label={submitted ? 'Submitted' : 'Open now'}
            tone={submitted ? 'green' : 'gold'}
          />
          <View style={styles.heroPrivacy}>
            <Ionicons name="lock-closed" size={13} color="#C6D7F2" />
            <Text style={styles.heroPrivacyText}>Private ballot</Text>
          </View>
        </View>
        <Text style={styles.heroKicker}>RIVERSIDE BOROUGH</Text>
        <Text style={styles.heroTitle}>Riverside community election</Text>
        <Text style={styles.heroBody}>
          {submitted
            ? 'Your ballot submission is confirmed. Your receipt never contains your choices.'
            : '2 contests · Usually takes 3–5 minutes · Closes tomorrow at 8:00 PM'}
        </Text>
        {!submitted && answeredCount > 0 ? (
          <View style={styles.draftProgress}>
            <View style={styles.draftProgressTop}>
              <Text style={styles.draftProgressText}>Draft in progress</Text>
              <Text style={styles.draftProgressText}>
                {answeredCount}/{totalContests} reviewed
              </Text>
            </View>
            <View style={styles.heroTrack}>
              <View
                style={[
                  styles.heroTrackFill,
                  { width: `${(answeredCount / totalContests) * 100}%` },
                ]}
              />
            </View>
          </View>
        ) : null}
        <Pressable
          accessibilityRole="button"
          onPress={onOpenBallot}
          style={({ pressed }) => [styles.heroButton, pressed && styles.buttonPressed]}>
          <Text style={styles.heroButtonText}>{primaryLabel}</Text>
          <Ionicons name="arrow-forward" size={19} color={colors.blueDark} />
        </Pressable>
      </View>

      <View style={styles.sectionHeader}>
        <Text accessibilityRole="header" style={styles.h2}>Ready to vote</Text>
        <Badge icon="checkmark-circle" label="3 checks passed" tone="green" />
      </View>
      <Panel elevated>
        <ReadinessRow
          body="Confirmed by Riverside election staff"
          icon="person-circle-outline"
          title="Identity verified"
        />
        <Divider />
        <ReadinessRow
          body="Correct ballot for your registered district"
          icon="document-text-outline"
          title="Ballot assigned"
        />
        <Divider />
        <ReadinessRow
          body="Submission requires a final review"
          icon="shield-checkmark-outline"
          title="Voting safeguards active"
        />
        <View style={styles.readinessActions}>
          <Pressable
            accessibilityRole="button"
            onPress={onSecurity}
            style={({ pressed }) => [styles.textAction, pressed && styles.pressOpacity]}>
            <Text style={styles.textActionLabel}>How your ballot is protected</Text>
            <Ionicons name="arrow-forward" size={17} color={colors.blueDark} />
          </Pressable>
        </View>
      </Panel>

      <View style={styles.sectionHeader}>
        <Text accessibilityRole="header" style={styles.h2}>Coming up</Text>
        <Pressable accessibilityRole="button" onPress={() => onOpenElection(elections[1])}>
          <Text style={styles.viewAll}>View details</Text>
        </Pressable>
      </View>
      <Pressable
        accessibilityRole="button"
        onPress={() => onOpenElection(elections[1])}
        style={({ pressed }) => [styles.upcomingCard, pressed && styles.pressOpacity]}>
        <View style={styles.calendarTile}>
          <Text style={styles.calendarMonth}>AUG</Text>
          <Text style={styles.calendarDay}>30</Text>
        </View>
        <View style={styles.flex}>
          <Badge label="Upcoming" tone="blue" />
          <Text style={styles.upcomingTitle}>Neighbourhood parks referendum</Text>
          <Text style={styles.upcomingBody}>Opens in 18 days · Riverside Borough</Text>
        </View>
        <Ionicons name="chevron-forward" size={20} color={colors.subtle} />
      </Pressable>

      <Pressable
        accessibilityRole="button"
        onPress={onHelp}
        style={({ pressed }) => [styles.helpStrip, pressed && styles.pressOpacity]}>
        <View style={styles.helpIcon}>
          <Ionicons name="headset-outline" size={22} color={colors.blueDark} />
        </View>
        <View style={styles.flex}>
          <Text style={styles.helpTitle}>Need help voting?</Text>
          <Text style={styles.helpBody}>Get accessible support without revealing your choices.</Text>
        </View>
        <Ionicons name="arrow-forward" size={19} color={colors.blueDark} />
      </Pressable>
      <PreviewNotice />
    </ScreenScroll>
  );
}

function ReadinessRow({ body, icon, title }: { body: string; icon: IconName; title: string }) {
  return (
    <View style={styles.readinessRow}>
      <View style={styles.readinessIcon}>
        <Ionicons name={icon} size={21} color={colors.teal} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.readinessTitle}>{title}</Text>
        <Text style={styles.readinessBody}>{body}</Text>
      </View>
      <Ionicons name="checkmark-circle" size={20} color={colors.teal} />
    </View>
  );
}

function ElectionsScreen({
  onOpenElection,
  submitted,
}: {
  onOpenElection: (election: Election) => void;
  submitted: boolean;
}) {
  const [filter, setFilter] = useState<'All' | 'Open' | 'Upcoming' | 'Completed'>('All');
  const filtered = elections.filter((election) => filter === 'All' || election.status === filter);
  return (
    <ScreenScroll>
      <ScreenHeading
        body="Only elections assigned to your verified voter profile appear here."
        eyebrow="RIVERSIDE BOROUGH"
        title="Your elections"
      />
      <View accessibilityRole="tablist" style={styles.filterRow}>
        {(['All', 'Open', 'Upcoming', 'Completed'] as const).map((item) => (
          <Pressable
            accessibilityRole="tab"
            accessibilityState={{ selected: filter === item }}
            key={item}
            onPress={() => setFilter(item)}
            style={({ pressed }) => [
              styles.filterChip,
              filter === item && styles.filterChipActive,
              pressed && styles.pressOpacity,
            ]}>
            <Text style={[styles.filterChipText, filter === item && styles.filterChipTextActive]}>
              {item}
            </Text>
          </Pressable>
        ))}
      </View>
      <View style={styles.electionList}>
        {filtered.map((election) => (
          <ElectionCard
            election={election}
            key={election.id}
            onPress={() => onOpenElection(election)}
            submitted={election.status === 'Open' && submitted}
          />
        ))}
      </View>
      <PreviewNotice />
    </ScreenScroll>
  );
}

function ElectionCard({
  election,
  onPress,
  submitted,
}: {
  election: Election;
  onPress: () => void;
  submitted: boolean;
}) {
  const tone = submitted
    ? 'green'
    : election.status === 'Open'
      ? 'gold'
      : election.status === 'Upcoming'
        ? 'blue'
        : 'neutral';
  const label = submitted ? 'Submitted' : election.status;
  const icon: IconName = submitted
    ? 'checkmark-circle'
    : election.status === 'Open'
      ? 'time'
      : election.status === 'Upcoming'
        ? 'calendar-outline'
        : 'ribbon-outline';
  return (
    <Pressable
      accessibilityHint={
        election.status === 'Open'
          ? 'Opens this ballot'
          : election.status === 'Completed'
            ? 'Opens published results'
            : 'Opens election details'
      }
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.electionCard, pressed && styles.cardPressed]}>
      <View style={styles.electionCardTop}>
        <Badge icon={icon} label={label} tone={tone} />
        <Text style={styles.electionDate}>{election.dateRange}</Text>
      </View>
      <Text style={styles.electionTitle}>{election.title}</Text>
      <Text style={styles.electionDescription}>{election.description}</Text>
      <View style={styles.electionMetaRow}>
        <Ionicons name="location-outline" size={17} color={colors.muted} />
        <Text style={styles.electionMeta}>{election.jurisdiction}</Text>
      </View>
      <View style={styles.electionCardFooter}>
        <Text style={styles.electionTiming}>{submitted ? 'Submission confirmed' : election.timing}</Text>
        <View style={styles.circleArrow}>
          <Ionicons name="arrow-forward" size={17} color={colors.blueDark} />
        </View>
      </View>
    </Pressable>
  );
}

function ResultsScreen() {
  const totalVotes = resultRows.reduce((sum, row) => sum + row.votes, 0);
  const leader = Math.max(...resultRows.map((row) => row.votes));
  return (
    <ScreenScroll>
      <ScreenHeading
        body="Results appear only after the election authority publishes them."
        eyebrow="PUBLISHED RESULTS"
        title="Election results"
      />
      <Panel elevated style={styles.resultsHero}>
        <View style={styles.resultsTopRow}>
          <Badge icon="ribbon" label="Certified" tone="green" />
          <Text style={styles.resultsTimestamp}>15 Jul · 4:30 PM</Text>
        </View>
        <Text style={styles.resultsElection}>Community library board</Text>
        <Text style={styles.resultsContest}>Library board representative</Text>
        <View style={styles.turnoutRow}>
          <View style={styles.turnoutStat}>
            <Text style={styles.turnoutNumber}>{totalVotes.toLocaleString()}</Text>
            <Text style={styles.turnoutLabel}>Ballots cast</Text>
          </View>
          <View style={styles.turnoutDivider} />
          <View style={styles.turnoutStat}>
            <Text style={styles.turnoutNumber}>49.4%</Text>
            <Text style={styles.turnoutLabel}>Turnout</Text>
          </View>
        </View>
      </Panel>

      <View style={styles.resultRows}>
        {resultRows.map((row, index) => {
          const percentage = (row.votes / totalVotes) * 100;
          return (
            <Panel key={row.name} style={styles.resultCard}>
              <View style={styles.resultIdentity}>
                <View style={[styles.rankTile, index === 0 && styles.rankTileLeader]}>
                  <Text style={[styles.rankText, index === 0 && styles.rankTextLeader]}>
                    {index + 1}
                  </Text>
                </View>
                <View style={styles.flex}>
                  <View style={styles.resultNameRow}>
                    <Text style={styles.resultName}>{row.name}</Text>
                    {index === 0 ? <Badge label="Elected" tone="green" /> : null}
                  </View>
                  <Text style={styles.resultParty}>{row.party}</Text>
                </View>
                <Text style={styles.resultPercent}>{percentage.toFixed(1)}%</Text>
              </View>
              <View
                accessibilityLabel={`${row.name}, ${row.votes.toLocaleString()} votes, ${percentage.toFixed(1)} percent`}
                accessibilityRole="progressbar"
                accessibilityValue={{ min: 0, max: leader, now: row.votes }}
                style={styles.resultTrack}>
                <View
                  style={[
                    styles.resultFill,
                    { backgroundColor: row.color, width: `${(row.votes / leader) * 100}%` },
                  ]}
                />
              </View>
              <Text style={styles.resultVotes}>{row.votes.toLocaleString()} votes</Text>
            </Panel>
          );
        })}
      </View>

      <View style={styles.integrityNote}>
        <Ionicons name="information-circle-outline" size={22} color={colors.blueDark} />
        <View style={styles.flex}>
          <Text style={styles.integrityTitle}>About these results</Text>
          <Text style={styles.integrityBody}>
            Totals are aggregate and never connect a voter to a selection. Results shown here are fictional preview data.
          </Text>
        </View>
      </View>
    </ScreenScroll>
  );
}

function UpdatesScreen({
  readUpdates,
  setReadUpdates,
}: {
  readUpdates: string[];
  setReadUpdates: (items: string[]) => void;
}) {
  const unread = updateItems.filter((item) => item.unread && !readUpdates.includes(item.id));
  const markAllRead = () => setReadUpdates(updateItems.map((item) => item.id));
  return (
    <ScreenScroll>
      <View style={styles.titleWithAction}>
        <ScreenHeading
          body="Election notices and receipt-safe account activity."
          title="Updates"
        />
        {unread.length > 0 ? (
          <Pressable accessibilityRole="button" onPress={markAllRead}>
            <Text style={styles.viewAll}>Mark all read</Text>
          </Pressable>
        ) : null}
      </View>
      {unread.length > 0 ? <Text style={styles.listGroupTitle}>NEW</Text> : null}
      {updateItems.map((item, index) => {
        const isRead = readUpdates.includes(item.id) || !item.unread;
        const icon: IconName =
          item.kind === 'ballot'
            ? 'document-text-outline'
            : item.kind === 'security'
              ? 'shield-checkmark-outline'
              : 'bar-chart-outline';
        return (
          <Pressable
            accessibilityHint="Marks this update as read"
            accessibilityRole="button"
            key={item.id}
            onPress={() => {
              if (!readUpdates.includes(item.id)) setReadUpdates([...readUpdates, item.id]);
            }}
            style={({ pressed }) => [
              styles.updateCard,
              !isRead && styles.updateCardUnread,
              pressed && styles.cardPressed,
            ]}>
            <View style={[styles.updateIcon, !isRead && styles.updateIconUnread]}>
              <Ionicons name={icon} size={22} color={!isRead ? colors.blue : colors.muted} />
            </View>
            <View style={styles.flex}>
              <View style={styles.updateTitleRow}>
                <Text style={styles.updateTitle}>{item.title}</Text>
                {!isRead ? <View accessibilityLabel="Unread" style={styles.updateUnreadDot} /> : null}
              </View>
              <Text style={styles.updateBody}>{item.body}</Text>
              <Text style={styles.updateTime}>{item.time}</Text>
            </View>
          </Pressable>
        );
      })}
      <View style={styles.privacyStrip}>
        <Ionicons name="eye-off-outline" size={21} color={colors.teal} />
        <Text style={styles.privacyStripText}>
          Updates may confirm participation, but never include your ballot choices.
        </Text>
      </View>
    </ScreenScroll>
  );
}

function ProfileScreen({
  highContrast,
  onHelp,
  onSecurity,
  reduceMotion,
  setHighContrast,
  setReduceMotion,
  setTextSize,
  textSize,
}: {
  highContrast: boolean;
  onHelp: () => void;
  onSecurity: () => void;
  reduceMotion: boolean;
  setHighContrast: (value: boolean) => void;
  setReduceMotion: (value: boolean) => void;
  setTextSize: (value: TextSizePreference) => void;
  textSize: TextSizePreference;
}) {
  return (
    <ScreenScroll>
      <ScreenHeading body="Manage your voter profile and app preferences." title="Profile" />
      <Panel elevated style={styles.profileCard}>
        <View style={styles.profileAvatar}>
          <Text style={styles.profileAvatarText}>MC</Text>
          <View style={styles.verifiedTick}>
            <Ionicons name="checkmark" size={12} color={colors.surface} />
          </View>
        </View>
        <Text style={styles.profileName}>Maya Chen</Text>
        <Text style={styles.profileEmail}>maya@demo.civicvote.app</Text>
        <Badge icon="shield-checkmark" label="Verified voter" tone="green" />
        <View style={styles.profileReference}>
          <Text style={styles.profileRefLabel}>VOTER REFERENCE</Text>
          <Text style={styles.profileRefValue}>CV-••••-4812</Text>
        </View>
      </Panel>

      <Text accessibilityRole="header" style={styles.settingsGroupTitle}>
        Accessibility
      </Text>
      <Panel>
        <View style={styles.settingBlock}>
          <View style={styles.settingLabelRow}>
            <View style={styles.settingIcon}>
              <Ionicons name="text-outline" size={20} color={colors.blueDark} />
            </View>
            <View style={styles.flex}>
              <Text style={styles.settingTitle}>Text size</Text>
              <Text style={styles.settingBody}>Adjust text without changing ballot content.</Text>
            </View>
          </View>
          <View accessibilityRole="radiogroup" style={styles.sizeOptions}>
            {([
              ['standard', 'A'],
              ['large', 'A+'],
              ['extra-large', 'A++'],
            ] as [TextSizePreference, string][]).map(([value, label]) => (
              <Pressable
                accessibilityLabel={
                  value === 'standard'
                    ? 'Standard text'
                    : value === 'large'
                      ? 'Large text'
                      : 'Extra large text'
                }
                accessibilityRole="radio"
                accessibilityState={{ selected: textSize === value }}
                key={value}
                onPress={() => setTextSize(value)}
                style={({ pressed }) => [
                  styles.sizeOption,
                  textSize === value && styles.sizeOptionActive,
                  pressed && styles.pressOpacity,
                ]}>
                <Text style={[styles.sizeOptionText, textSize === value && styles.sizeOptionTextActive]}>
                  {label}
                </Text>
              </Pressable>
            ))}
          </View>
        </View>
        <Divider />
        <SettingToggle
          body="Strengthen borders and visual separation."
          icon="contrast-outline"
          onValueChange={setHighContrast}
          title="High contrast"
          value={highContrast}
        />
        <Divider />
        <SettingToggle
          body="Minimise non-essential transitions."
          icon="sparkles-outline"
          onValueChange={setReduceMotion}
          title="Reduce motion"
          value={reduceMotion}
        />
      </Panel>

      <Text accessibilityRole="header" style={styles.settingsGroupTitle}>
        Account & support
      </Text>
      <Panel>
        <SettingsLink
          body="Verification, privacy and session status"
          icon="shield-checkmark-outline"
          onPress={onSecurity}
          title="Security and privacy"
        />
        <Divider />
        <SettingsLink
          body="English (United Kingdom)"
          icon="language-outline"
          onPress={() =>
            Alert.alert(
              'Ballot language',
              'Official translated ballot content must be supplied and approved by the election authority. English is the only language in this fictional preview.',
            )
          }
          title="Language"
        />
        <Divider />
        <SettingsLink
          body="Accessible support and common questions"
          icon="help-buoy-outline"
          onPress={onHelp}
          title="Help centre"
        />
      </Panel>
      <Text style={styles.versionText}>CivicVote product preview · Version 4.1.0</Text>
      <PreviewNotice />
    </ScreenScroll>
  );
}

function SettingToggle({
  body,
  icon,
  onValueChange,
  title,
  value,
}: {
  body: string;
  icon: IconName;
  onValueChange: (value: boolean) => void;
  title: string;
  value: boolean;
}) {
  return (
    <View style={styles.settingRow}>
      <View style={styles.settingIcon}>
        <Ionicons name={icon} size={20} color={colors.blueDark} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.settingTitle}>{title}</Text>
        <Text style={styles.settingBody}>{body}</Text>
      </View>
      <Switch
        accessibilityLabel={title}
        ios_backgroundColor={colors.borderStrong}
        onValueChange={onValueChange}
        thumbColor={colors.surface}
        trackColor={{ false: colors.borderStrong, true: colors.blue }}
        value={value}
      />
    </View>
  );
}

function SettingsLink({
  body,
  icon,
  onPress,
  title,
}: {
  body: string;
  icon: IconName;
  onPress: () => void;
  title: string;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.settingRow, pressed && styles.pressOpacity]}>
      <View style={styles.settingIcon}>
        <Ionicons name={icon} size={20} color={colors.blueDark} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.settingTitle}>{title}</Text>
        <Text style={styles.settingBody}>{body}</Text>
      </View>
      <Ionicons name="chevron-forward" size={20} color={colors.subtle} />
    </Pressable>
  );
}

function PreviewNotice() {
  return (
    <View style={styles.previewNotice}>
      <Ionicons name="flask-outline" size={17} color={colors.gold} />
      <Text style={styles.previewNoticeText}>
        Fictional product preview — no action here is an official vote.
      </Text>
    </View>
  );
}

function BallotHeader({
  onBack,
  onClose,
  progress,
  title,
}: {
  onBack?: () => void;
  onClose: () => void;
  progress?: { current: number; total: number };
  title: string;
}) {
  const percentage = progress ? (progress.current / progress.total) * 100 : 0;
  return (
    <View style={styles.ballotHeaderWrap}>
      <View style={styles.ballotHeader}>
        {onBack ? (
          <IconButton icon="arrow-back" label="Go back" onPress={onBack} />
        ) : (
          <View style={styles.ballotHeaderSpacer} />
        )}
        <View style={styles.ballotHeaderTitleWrap}>
          <Text style={styles.ballotHeaderEyebrow}>RIVERSIDE 2026</Text>
          <Text numberOfLines={1} style={styles.ballotHeaderTitle}>
            {title}
          </Text>
        </View>
        <IconButton icon="close" label="Save and close ballot" onPress={onClose} />
      </View>
      {progress ? (
        <View
          accessibilityLabel={`Step ${progress.current} of ${progress.total}`}
          accessibilityRole="progressbar"
          accessibilityValue={{ min: 0, max: progress.total, now: progress.current }}
          style={styles.ballotProgressTrack}>
          <View style={[styles.ballotProgressFill, { width: `${percentage}%` }]} />
        </View>
      ) : null}
    </View>
  );
}

function BallotIntro({
  answeredCount,
  election,
  onBegin,
  onClose,
  onHow,
}: {
  answeredCount: number;
  election: Election;
  onBegin: () => void;
  onClose: () => void;
  onHow: () => void;
}) {
  return (
    <View style={styles.ballotPage}>
      <BallotHeader onClose={onClose} title="Before you begin" />
      <ScrollView contentContainerStyle={styles.ballotIntroContent} showsVerticalScrollIndicator={false}>
        <View style={styles.ballotIntroIcon}>
          <Ionicons name="document-text" size={30} color={colors.blue} />
        </View>
        <Text accessibilityRole="header" style={styles.ballotIntroTitle}>
          {answeredCount > 0 ? 'Continue your ballot' : 'Your ballot is ready'}
        </Text>
        <Text style={styles.ballotIntroBody}>{election.title}</Text>
        <View style={styles.ballotFacts}>
          <BallotFact icon="layers-outline" label={`${election.contests.length} contests`} />
          <BallotFact icon="time-outline" label="About 3–5 min" />
          <BallotFact icon="calendar-outline" label="Closes tomorrow, 8 PM" />
        </View>
        <Panel style={styles.beforePanel}>
          <Text style={styles.beforeTitle}>You stay in control</Text>
          <BeforeRow
            body="Move one contest at a time with clear progress."
            icon="list-outline"
            title="Simple, linear ballot"
          />
          <BeforeRow
            body="Edit every choice from the review screen."
            icon="create-outline"
            title="Review before casting"
          />
          <BeforeRow
            body="Your receipt confirms submission without showing choices."
            icon="eye-off-outline"
            title="Receipt-safe privacy"
          />
        </Panel>
        <View style={styles.ballotCallout}>
          <Ionicons name="lock-closed-outline" size={20} color={colors.teal} />
          <Text style={styles.ballotCalloutText}>
            Choices stay in this app session until you cast. Leaving does not submit your ballot.
          </Text>
        </View>
        <Button
          icon="arrow-forward"
          label={answeredCount > 0 ? 'Continue ballot' : 'Begin ballot'}
          onPress={onBegin}
        />
        <Pressable
          accessibilityRole="button"
          onPress={onHow}
          style={({ pressed }) => [styles.howLink, pressed && styles.pressOpacity]}>
          <Ionicons name="help-circle-outline" size={19} color={colors.blueDark} />
          <Text style={styles.howLinkText}>How voting works</Text>
        </Pressable>
        <PreviewNotice />
      </ScrollView>
    </View>
  );
}

function BallotFact({ icon, label }: { icon: IconName; label: string }) {
  return (
    <View style={styles.ballotFact}>
      <Ionicons name={icon} size={18} color={colors.blueDark} />
      <Text style={styles.ballotFactText}>{label}</Text>
    </View>
  );
}

function BeforeRow({ body, icon, title }: { body: string; icon: IconName; title: string }) {
  return (
    <View style={styles.beforeRow}>
      <View style={styles.beforeIcon}>
        <Ionicons name={icon} size={19} color={colors.blueDark} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.beforeRowTitle}>{title}</Text>
        <Text style={styles.beforeRowBody}>{body}</Text>
      </View>
    </View>
  );
}

function ContestScreen({
  choices,
  contestIndex,
  election,
  onBack,
  onChoose,
  onClose,
  onDetails,
  onNext,
  onSkip,
}: {
  choices: ChoiceMap;
  contestIndex: number;
  election: Election;
  onBack: () => void;
  onChoose: (contestId: string, candidateId: string) => void;
  onClose: () => void;
  onDetails: (candidate: Candidate) => void;
  onNext: () => void;
  onSkip: () => void;
}) {
  const contest = election.contests[contestIndex];
  const hasReviewed = Object.prototype.hasOwnProperty.call(choices, contest.id);
  const selectedId = choices[contest.id];
  return (
    <View style={styles.ballotPage}>
      <BallotHeader
        onBack={onBack}
        onClose={onClose}
        progress={{ current: contestIndex + 1, total: election.contests.length + 1 }}
        title={`Contest ${contestIndex + 1} of ${election.contests.length}`}
      />
      <ScrollView contentContainerStyle={styles.contestContent} showsVerticalScrollIndicator={false}>
        <View style={styles.contestTopline}>
          <Text style={styles.contestNumber}>CONTEST {contestIndex + 1} OF {election.contests.length}</Text>
          <Badge label="Select one" tone="blue" />
        </View>
        <Text accessibilityRole="header" style={styles.contestTitle}>{contest.title}</Text>
        <Text style={styles.contestInstructions}>{contest.instructions}</Text>
        <View accessibilityRole="radiogroup" style={styles.choiceList}>
          {contest.candidates.map((candidate) => (
            <CandidateChoice
              candidate={candidate}
              key={candidate.id}
              onChoose={() => onChoose(contest.id, candidate.id)}
              onDetails={() => onDetails(candidate)}
              selected={selectedId === candidate.id}
            />
          ))}
        </View>
        {selectedId === null ? (
          <View accessibilityLiveRegion="polite" style={styles.skipConfirmation}>
            <Ionicons name="remove-circle-outline" size={20} color={colors.gold} />
            <Text style={styles.skipConfirmationText}>You chose to leave this contest blank.</Text>
          </View>
        ) : null}
        <Text style={styles.equalTreatmentNote}>
          Candidates and options are shown in official ballot order with equal visual treatment.
        </Text>
      </ScrollView>
      <View style={styles.ballotFooter}>
        <View style={styles.ballotFooterInner}>
          <Button
            disabled={!hasReviewed || selectedId === null}
            icon="arrow-forward"
            label={contestIndex === election.contests.length - 1 ? 'Review ballot' : 'Next contest'}
            onPress={onNext}
          />
          <Pressable
            accessibilityHint="Records no selection for this contest"
            accessibilityRole="button"
            onPress={onSkip}
            style={({ pressed }) => [styles.skipLink, pressed && styles.pressOpacity]}>
            <Text style={styles.skipLinkText}>
              {selectedId === null ? 'Continue with no selection' : 'Leave this contest blank'}
            </Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}

function CandidateChoice({
  candidate,
  onChoose,
  onDetails,
  selected,
}: {
  candidate: Candidate;
  onChoose: () => void;
  onDetails: () => void;
  selected: boolean;
}) {
  return (
    <View style={[styles.choiceCard, selected && styles.choiceCardSelected]}>
      <Pressable
        accessibilityLabel={`${candidate.name}, ${candidate.party}`}
        accessibilityRole="radio"
        accessibilityState={{ selected }}
        onPress={onChoose}
        style={({ pressed }) => [styles.choiceSelectArea, pressed && styles.pressOpacity]}>
        <View style={[styles.candidateInitials, { backgroundColor: `${candidate.color}16` }]}>
          <Text style={[styles.candidateInitialsText, { color: candidate.color }]}>
            {candidate.initials}
          </Text>
        </View>
        <View style={styles.flex}>
          <Text style={styles.choiceName}>{candidate.name}</Text>
          <Text style={styles.choiceParty}>
            {candidate.party} · {candidate.abbreviation}
          </Text>
        </View>
        <View style={[styles.radioOuter, selected && styles.radioOuterSelected]}>
          {selected ? <View style={styles.radioInner} /> : null}
        </View>
      </Pressable>
      <Divider />
      <Pressable
        accessibilityLabel={`View details for ${candidate.name}`}
        accessibilityRole="button"
        onPress={onDetails}
        style={({ pressed }) => [styles.detailsLink, pressed && styles.pressOpacity]}>
        <Ionicons name="information-circle-outline" size={18} color={colors.blueDark} />
        <Text style={styles.detailsLinkText}>
          {candidate.party === 'Referendum option' ? 'Read what this means' : 'Candidate details'}
        </Text>
        <Ionicons name="chevron-forward" size={17} color={colors.blueDark} />
      </Pressable>
    </View>
  );
}

function ReviewScreen({
  choices,
  election,
  error,
  onBack,
  onCast,
  onClose,
  onEdit,
  reviewed,
  setReviewed,
  submitting,
}: {
  choices: ChoiceMap;
  election: Election;
  error: string | null;
  onBack: () => void;
  onCast: () => void;
  onClose: () => void;
  onEdit: (index: number) => void;
  reviewed: boolean;
  setReviewed: (value: boolean) => void;
  submitting: boolean;
}) {
  const blankCount = election.contests.filter((contest) => choices[contest.id] === null).length;
  return (
    <View style={styles.ballotPage}>
      <BallotHeader
        onBack={onBack}
        onClose={onClose}
        progress={{ current: election.contests.length + 1, total: election.contests.length + 1 }}
        title="Review ballot"
      />
      <ScrollView contentContainerStyle={styles.reviewContent} showsVerticalScrollIndicator={false}>
        <Text style={styles.contestNumber}>FINAL REVIEW</Text>
        <Text accessibilityRole="header" style={styles.reviewTitle}>Check every choice</Text>
        <Text style={styles.reviewBody}>
          This is your last chance to make changes. A submitted ballot cannot be edited in this preview.
        </Text>
        {blankCount > 0 ? (
          <View style={styles.undervoteWarning}>
            <Ionicons name="alert-circle-outline" size={22} color={colors.gold} />
            <Text style={styles.undervoteWarningText}>
              {blankCount} {blankCount === 1 ? 'contest has' : 'contests have'} no selection. You may still cast this ballot.
            </Text>
          </View>
        ) : null}
        <View style={styles.reviewList}>
          {election.contests.map((contest, index) => {
            const candidate = contest.candidates.find((item) => item.id === choices[contest.id]);
            return (
              <Panel key={contest.id} style={styles.reviewCard}>
                <View style={styles.reviewCardTop}>
                  <View style={styles.reviewNumber}>
                    <Text style={styles.reviewNumberText}>{index + 1}</Text>
                  </View>
                  <View style={styles.flex}>
                    <Text style={styles.reviewContest}>{contest.title}</Text>
                    <Text style={[styles.reviewChoice, !candidate && styles.reviewChoiceBlank]}>
                      {candidate?.name ?? 'No selection'}
                    </Text>
                    {candidate ? <Text style={styles.reviewParty}>{candidate.party}</Text> : null}
                  </View>
                </View>
                <Pressable
                  accessibilityLabel={`Change selection for ${contest.title}`}
                  accessibilityRole="button"
                  onPress={() => onEdit(index)}
                  style={({ pressed }) => [styles.changeButton, pressed && styles.pressOpacity]}>
                  <Ionicons name="create-outline" size={18} color={colors.blueDark} />
                  <Text style={styles.changeButtonText}>Change</Text>
                </Pressable>
              </Panel>
            );
          })}
        </View>
        <Pressable
          accessibilityRole="checkbox"
          accessibilityState={{ checked: reviewed }}
          onPress={() => setReviewed(!reviewed)}
          style={({ pressed }) => [styles.reviewCheck, pressed && styles.pressOpacity]}>
          <View style={[styles.checkBox, reviewed && styles.checkBoxChecked]}>
            {reviewed ? <Ionicons name="checkmark" size={17} color={colors.surface} /> : null}
          </View>
          <Text style={styles.reviewCheckText}>
            I reviewed every contest and understand that casting is final.
          </Text>
        </Pressable>
        {error ? (
          <View accessibilityLiveRegion="assertive" style={styles.errorBox}>
            <Ionicons name="alert-circle" size={21} color={colors.red} />
            <View style={styles.flex}>
              <Text style={styles.errorTitle}>Submission not confirmed</Text>
              <Text style={styles.errorBody}>{error}</Text>
            </View>
          </View>
        ) : null}
        <Button
          disabled={!reviewed}
          icon="lock-closed"
          label="Cast my ballot"
          loading={submitting}
          onPress={onCast}
        />
        <Text style={styles.castPrivacyText}>
          Your submission receipt will not contain your selections.
        </Text>
      </ScrollView>
    </View>
  );
}

function ReceiptScreen({
  election,
  onDone,
  onExplain,
  onShare,
  receipt,
  submittedAt,
}: {
  election: Election;
  onDone: () => void;
  onExplain: () => void;
  onShare: () => void;
  receipt: string | null;
  submittedAt: string | null;
}) {
  const submittedLabel = submittedAt
    ? new Date(submittedAt).toLocaleString('en-GB', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
      })
    : 'Status available after submission';
  return (
    <View style={styles.ballotPage}>
      <BallotHeader onClose={onDone} title="Submission complete" />
      <ScrollView contentContainerStyle={styles.receiptContent} showsVerticalScrollIndicator={false}>
        <View style={styles.successHalo}>
          <View style={styles.successIcon}>
            <Ionicons name="checkmark" size={40} color={colors.surface} />
          </View>
        </View>
        <Badge icon="checkmark-circle" label="Submission confirmed" tone="green" />
        <Text accessibilityRole="header" style={styles.receiptTitle}>Your ballot was received</Text>
        <Text style={styles.receiptBody}>
          You have finished {election.shortTitle}. Your in-progress choices have been cleared from this app.
        </Text>
        <Panel elevated style={styles.receiptCard}>
          <View style={styles.receiptCardHeader}>
            <View>
              <Text style={styles.receiptLabel}>SUBMISSION RECEIPT</Text>
              <Text selectable style={styles.receiptCode}>{receipt ?? 'CV-PREVIEW'}</Text>
            </View>
            <View style={styles.receiptShield}>
              <Ionicons name="shield-checkmark" size={25} color={colors.teal} />
            </View>
          </View>
          <Divider />
          <ReceiptDetail label="Election" value={election.shortTitle} />
          <ReceiptDetail label="Status" value="Received" />
          <ReceiptDetail label="Submitted" value={submittedLabel} />
          <View style={styles.receiptPrivacy}>
            <Ionicons name="eye-off-outline" size={18} color={colors.teal} />
            <Text style={styles.receiptPrivacyText}>This receipt does not reveal how you voted.</Text>
          </View>
        </Panel>
        <Button icon="share-outline" label="Share receipt safely" onPress={onShare} variant="secondary" />
        <Pressable
          accessibilityRole="button"
          onPress={onExplain}
          style={({ pressed }) => [styles.howLink, pressed && styles.pressOpacity]}>
          <Ionicons name="information-circle-outline" size={19} color={colors.blueDark} />
          <Text style={styles.howLinkText}>What this receipt means</Text>
        </Pressable>
        <View style={styles.receiptDivider} />
        <Button label="Return to home" onPress={onDone} />
        <PreviewNotice />
      </ScrollView>
    </View>
  );
}

function ReceiptDetail({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.receiptDetail}>
      <Text style={styles.receiptDetailLabel}>{label}</Text>
      <Text style={styles.receiptDetailValue}>{value}</Text>
    </View>
  );
}

function CandidateSheet({ candidate, onClose }: { candidate: Candidate | null; onClose: () => void }) {
  if (!candidate) return null;
  const isReferendum = candidate.party === 'Referendum option';
  return (
    <Sheet
      onClose={onClose}
      title={isReferendum ? 'Referendum option' : 'Candidate details'}
      visible>
      <View style={styles.candidateSheetIdentity}>
        <View style={[styles.candidateSheetInitials, { backgroundColor: `${candidate.color}16` }]}>
          <Text style={[styles.candidateSheetInitialsText, { color: candidate.color }]}>
            {candidate.initials}
          </Text>
        </View>
        <View style={styles.flex}>
          <Text style={styles.candidateSheetName}>{candidate.name}</Text>
          <Text style={styles.candidateSheetParty}>
            {candidate.party} · {candidate.abbreviation}
          </Text>
        </View>
      </View>
      <Text style={styles.sheetSectionTitle}>{isReferendum ? 'What this vote means' : 'Statement'}</Text>
      <Text style={styles.sheetParagraph}>{candidate.platform}</Text>
      <Text style={styles.sheetSectionTitle}>{isReferendum ? 'Key effects' : 'Priorities'}</Text>
      {candidate.priorities.map((priority) => (
        <View key={priority} style={styles.priorityRow}>
          <View style={[styles.priorityBullet, { backgroundColor: candidate.color }]} />
          <Text style={styles.priorityText}>{priority}</Text>
        </View>
      ))}
      <Text style={styles.sheetSectionTitle}>{isReferendum ? 'Outcome' : 'Experience'}</Text>
      <Text style={styles.sheetParagraph}>{candidate.experience}</Text>
      <View style={styles.neutralityNote}>
        <Ionicons name="information-circle-outline" size={20} color={colors.muted} />
        <Text style={styles.neutralityText}>
          Fictional information supplied for this preview. CivicVote does not endorse any candidate or option.
        </Text>
      </View>
      <Button label="Done" onPress={onClose} variant="secondary" />
    </Sheet>
  );
}

function InformationSheets({
  election,
  onClose,
  sheet,
}: {
  election: Election;
  onClose: () => void;
  sheet: SheetName;
}) {
  if (!sheet) return null;
  if (sheet === 'help') {
    return (
      <Sheet onClose={onClose} title="Help & accessible support" visible>
        <Text style={styles.sheetLead}>Get help with the process — never with who to choose.</Text>
        <SupportOption icon="chatbubbles-outline" title="Live chat" body="Typical reply in under 2 minutes" />
        <SupportOption icon="call-outline" title="Call election support" body="0800 555 0142 · 8 AM–8 PM" />
        <SupportOption icon="accessibility-outline" title="Accessibility assistance" body="Screen reader, mobility and language support" />
        <View style={styles.supportPrivacy}>
          <Ionicons name="eye-off-outline" size={20} color={colors.teal} />
          <Text style={styles.supportPrivacyText}>
            Support agents cannot see your ballot choices and will never ask how you voted.
          </Text>
        </View>
        <Button label="Close" onPress={onClose} variant="secondary" />
      </Sheet>
    );
  }
  if (sheet === 'security') {
    return (
      <Sheet onClose={onClose} title="Security & privacy" visible>
        <Text style={styles.sheetLead}>
          CivicVote separates eligibility and submission records from anonymous ballot choices.
        </Text>
        <SecurityStep icon="person-outline" title="Eligibility checked" body="Only your assigned ballot is shown after profile verification." />
        <SecurityStep icon="git-compare-outline" title="Data separated" body="Submission status is stored separately from ballot selections." />
        <SecurityStep icon="repeat-outline" title="One transaction" body="The server checks eligibility, timing and duplicate submission atomically." />
        <SecurityStep icon="receipt-outline" title="Receipt-safe status" body="Your receipt confirms submission but never repeats a choice." />
        <View style={styles.securityCaution}>
          <Text style={styles.securityCautionTitle}>Preview boundary</Text>
          <Text style={styles.securityCautionBody}>
            This interface is not certified for a binding public election. Certification, independent review and jurisdiction approval remain required.
          </Text>
        </View>
        <Button label="Got it" onPress={onClose} />
      </Sheet>
    );
  }
  if (sheet === 'how') {
    return (
      <Sheet onClose={onClose} title="How voting works" visible>
        <Text style={styles.sheetLead}>Four clear steps, with a chance to recover before the final action.</Text>
        <NumberedStep number="1" title="Review one contest" body="Read the instruction and compare every option in equal ballot order." />
        <NumberedStep number="2" title="Select or leave blank" body="You can make one selection or intentionally leave a contest blank." />
        <NumberedStep number="3" title="Check the full ballot" body="Edit any contest from one consistent review screen." />
        <NumberedStep number="4" title="Cast once" body="Confirm the irreversible action, then keep a receipt that reveals no choices." />
        <Button label="Continue" onPress={onClose} />
      </Sheet>
    );
  }
  if (sheet === 'receipt') {
    return (
      <Sheet onClose={onClose} title="About your receipt" visible>
        <View style={styles.receiptExplainIcon}>
          <Ionicons name="receipt-outline" size={30} color={colors.blueDark} />
        </View>
        <Text style={styles.sheetLead}>
          A submission receipt is designed to help you recover safely after a network interruption.
        </Text>
        <SecurityStep icon="checkmark-circle-outline" title="It confirms" body="The authority accepted one ballot submission for your assignment." />
        <SecurityStep icon="close-circle-outline" title="It does not prove a choice" body="The code cannot be used to show another person who you selected." />
        <SecurityStep icon="time-outline" title="Keep it until certification" body="Use it when contacting official election support about submission status." />
        <Button label="Done" onPress={onClose} variant="secondary" />
      </Sheet>
    );
  }
  return (
    <Sheet onClose={onClose} title="Election details" visible>
      <Badge icon="calendar-outline" label={election.status} tone="blue" />
      <Text style={styles.electionSheetTitle}>{election.title}</Text>
      <Text style={styles.sheetParagraph}>{election.description}</Text>
      <Panel style={styles.electionSheetFacts}>
        <ReceiptDetail label="Jurisdiction" value={election.jurisdiction} />
        <ReceiptDetail label="Voting period" value={election.dateRange} />
        <ReceiptDetail label="Availability" value={election.timing} />
      </Panel>
      <View style={styles.reminderNote}>
        <Ionicons name="notifications-outline" size={21} color={colors.blueDark} />
        <Text style={styles.reminderNoteText}>A reminder is enabled for the day this ballot opens.</Text>
      </View>
      <Button label="Done" onPress={onClose} />
    </Sheet>
  );
}

function SupportOption({ icon, title, body }: { icon: IconName; title: string; body: string }) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => Alert.alert('Product preview', `${title} is not connected in this fictional preview.`)}
      style={({ pressed }) => [styles.supportOption, pressed && styles.pressOpacity]}>
      <View style={styles.supportOptionIcon}>
        <Ionicons name={icon} size={21} color={colors.blueDark} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.supportOptionTitle}>{title}</Text>
        <Text style={styles.supportOptionBody}>{body}</Text>
      </View>
      <Ionicons name="chevron-forward" size={19} color={colors.subtle} />
    </Pressable>
  );
}

function SecurityStep({ icon, title, body }: { icon: IconName; title: string; body: string }) {
  return (
    <View style={styles.securityStep}>
      <View style={styles.securityStepIcon}>
        <Ionicons name={icon} size={21} color={colors.teal} />
      </View>
      <View style={styles.flex}>
        <Text style={styles.securityStepTitle}>{title}</Text>
        <Text style={styles.securityStepBody}>{body}</Text>
      </View>
    </View>
  );
}

function NumberedStep({ number, title, body }: { number: string; title: string; body: string }) {
  return (
    <View style={styles.numberedStep}>
      <View style={styles.numberedStepNumber}>
        <Text style={styles.numberedStepNumberText}>{number}</Text>
      </View>
      <View style={styles.flex}>
        <Text style={styles.securityStepTitle}>{title}</Text>
        <Text style={styles.securityStepBody}>{body}</Text>
      </View>
    </View>
  );
}

function CastConfirmation({
  onCancel,
  onConfirm,
  visible,
}: {
  onCancel: () => void;
  onConfirm: () => void;
  visible: boolean;
}) {
  const { reduceMotion } = usePreferences();
  return (
    <Modal
      animationType={reduceMotion ? 'none' : 'fade'}
      onRequestClose={onCancel}
      transparent
      visible={visible}>
      <View style={styles.confirmScrim}>
        <View accessibilityViewIsModal style={styles.confirmDialog}>
          <View style={styles.confirmIcon}>
            <Ionicons name="lock-closed" size={28} color={colors.blueDark} />
          </View>
          <Text accessibilityRole="header" style={styles.confirmTitle}>Cast your ballot?</Text>
          <Text style={styles.confirmBody}>
            This is the final step. After submission, your selections cannot be viewed or changed in this preview.
          </Text>
          <View style={styles.confirmWarning}>
            <Ionicons name="information-circle" size={19} color={colors.gold} />
            <Text style={styles.confirmWarningText}>Your receipt will not show how you voted.</Text>
          </View>
          <Button icon="lock-closed" label="Yes, cast ballot" onPress={onConfirm} />
          <View style={styles.confirmCancel}>
            <Button label="Go back and review" onPress={onCancel} variant="secondary" />
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  loadingScreen: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.canvas },
  safe: { flex: 1, backgroundColor: colors.canvas },
  safeHighContrast: { backgroundColor: colors.surface },
  flex: { flex: 1 },
  main: { flex: 1 },
  appHeader: {
    minHeight: 68,
    backgroundColor: colors.surface,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    zIndex: 2,
  },
  brandRow: { flexDirection: 'row', alignItems: 'center', gap: 9 },
  logoMark: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.blue },
  logoMarkInverse: { backgroundColor: colors.surface },
  brandText: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 18, lineHeight: 24, color: colors.ink, letterSpacing: -0.4 },
  brandTextInverse: { color: colors.surface },
  headerActions: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  previewLabel: { height: 32, flexDirection: 'row', alignItems: 'center', gap: 7, borderRadius: 99, backgroundColor: colors.goldPale, paddingHorizontal: 10 },
  previewDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: colors.gold },
  previewText: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 13, color: colors.gold, textTransform: 'uppercase', letterSpacing: 0.4 },
  desktopShell: { flex: 1, flexDirection: 'row' },
  desktopMain: { flex: 1, minWidth: 0 },
  sideNav: { width: 246, backgroundColor: colors.navyDeep, paddingHorizontal: 20, paddingTop: 24, paddingBottom: 24 },
  sideContext: { marginTop: 34, marginLeft: 11, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: '#7F96B8', letterSpacing: 1.1 },
  sideNavItems: { marginTop: 12, gap: 5 },
  sideNavItem: { minHeight: 50, borderRadius: 14, flexDirection: 'row', alignItems: 'center', gap: 13, paddingHorizontal: 13 },
  sideNavItemActive: { backgroundColor: '#EDF3FF' },
  sideNavLabel: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 13, lineHeight: 18, color: '#C5D1E3' },
  sideNavLabelActive: { color: colors.navyDeep, fontFamily: 'Montserrat_700Bold' },
  navCount: { minWidth: 24, height: 24, borderRadius: 12, paddingHorizontal: 6, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.blue },
  navCountText: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 13, color: colors.surface },
  sideVerified: { marginTop: 'auto', borderRadius: 16, backgroundColor: '#102848', padding: 14, flexDirection: 'row', gap: 10, alignItems: 'center' },
  sideVerifiedTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.surface },
  sideVerifiedBody: { marginTop: 2, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 14, color: '#AFC1DD' },
  bottomNav: { minHeight: 70, paddingTop: 7, paddingHorizontal: 4, backgroundColor: colors.surface, borderTopWidth: 1, borderTopColor: colors.border, flexDirection: 'row', ...shadows.card },
  bottomNavItem: { flex: 1, minWidth: 0, alignItems: 'center', justifyContent: 'center' },
  navIconWrap: { width: 42, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  navIconWrapActive: { backgroundColor: colors.bluePale },
  unreadDot: { position: 'absolute', right: 8, top: 3, width: 8, height: 8, borderRadius: 4, backgroundColor: colors.red, borderWidth: 1.5, borderColor: colors.surface },
  bottomNavText: { marginTop: 3, fontFamily: 'Montserrat_600SemiBold', fontSize: 9, lineHeight: 12, color: colors.muted },
  bottomNavTextActive: { color: colors.blueDark, fontFamily: 'Montserrat_700Bold' },
  screenContent: { width: '100%', maxWidth: 850, alignSelf: 'center', paddingHorizontal: 20, paddingTop: 28, paddingBottom: 38 },
  screenHeading: { flex: 1, marginBottom: 23 },
  eyebrow: { marginBottom: 7, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark, letterSpacing: 1.05 },
  h1: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 29, lineHeight: 37, color: colors.ink, letterSpacing: -0.9 },
  intro: { marginTop: 7, maxWidth: 610, fontFamily: 'Montserrat_400Regular', fontSize: 14, lineHeight: 22, color: colors.muted },
  h2: { fontFamily: 'Montserrat_700Bold', fontSize: 18, lineHeight: 25, color: colors.ink, letterSpacing: -0.35 },
  homeGreeting: { flexDirection: 'row', alignItems: 'center', gap: 16, marginBottom: 22 },
  dateLabel: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark, letterSpacing: 1.05 },
  homeTitle: { marginTop: 5, fontFamily: 'Montserrat_800ExtraBold', fontSize: 27, lineHeight: 35, color: colors.ink, letterSpacing: -0.85 },
  homeSubtitle: { marginTop: 4, fontFamily: 'Montserrat_400Regular', fontSize: 14, lineHeight: 21, color: colors.muted },
  profileMini: { width: 52, height: 52, borderRadius: 18, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bluePale, borderWidth: 2, borderColor: colors.surface },
  profileMiniText: { fontFamily: 'Montserrat_700Bold', fontSize: 14, lineHeight: 19, color: colors.blueDark },
  heroCard: { overflow: 'hidden', borderRadius: 25, backgroundColor: colors.navyDeep, padding: 22, ...shadows.floating },
  heroOrbOne: { position: 'absolute', width: 170, height: 170, borderRadius: 85, right: -65, top: -70, backgroundColor: '#183A69' },
  heroOrbTwo: { position: 'absolute', width: 110, height: 110, borderRadius: 55, right: 43, bottom: -68, backgroundColor: '#133056' },
  heroTopRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  heroPrivacy: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  heroPrivacyText: { fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 14, color: '#C6D7F2' },
  heroKicker: { marginTop: 28, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: '#8FB0E5', letterSpacing: 1.1 },
  heroTitle: { marginTop: 7, maxWidth: 490, fontFamily: 'Montserrat_800ExtraBold', fontSize: 25, lineHeight: 33, color: colors.surface, letterSpacing: -0.65 },
  heroBody: { marginTop: 8, maxWidth: 540, fontFamily: 'Montserrat_400Regular', fontSize: 13, lineHeight: 21, color: '#C6D7F2' },
  draftProgress: { marginTop: 17, borderRadius: 13, backgroundColor: 'rgba(255,255,255,0.09)', padding: 12 },
  draftProgressTop: { flexDirection: 'row', justifyContent: 'space-between', gap: 10 },
  draftProgressText: { fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 14, color: '#D9E6FA' },
  heroTrack: { marginTop: 9, height: 5, borderRadius: 99, overflow: 'hidden', backgroundColor: 'rgba(255,255,255,0.16)' },
  heroTrackFill: { height: '100%', borderRadius: 99, backgroundColor: '#90B3F2' },
  heroButton: { marginTop: 20, minHeight: 52, borderRadius: 16, backgroundColor: colors.surface, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, paddingHorizontal: 18 },
  heroButtonText: { fontFamily: 'Montserrat_700Bold', fontSize: 14, lineHeight: 19, color: colors.blueDark },
  buttonPressed: { transform: [{ scale: 0.988 }], opacity: 0.92 },
  sectionHeader: { marginTop: 29, marginBottom: 12, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  readinessRow: { minHeight: 75, paddingHorizontal: 16, paddingVertical: 13, flexDirection: 'row', alignItems: 'center', gap: 12 },
  readinessIcon: { width: 40, height: 40, borderRadius: 14, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.tealPale },
  readinessTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 13, lineHeight: 18, color: colors.ink },
  readinessBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 17, color: colors.muted },
  readinessActions: { borderTopWidth: 1, borderTopColor: colors.border, padding: 10 },
  textAction: { minHeight: 42, borderRadius: 12, backgroundColor: colors.bluePale, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7, paddingHorizontal: 12 },
  textActionLabel: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.blueDark },
  viewAll: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.blueDark },
  upcomingCard: { minHeight: 118, borderRadius: 20, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, padding: 15, flexDirection: 'row', alignItems: 'center', gap: 13, ...shadows.card },
  calendarTile: { width: 58, height: 66, borderRadius: 16, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  calendarMonth: { fontFamily: 'Montserrat_700Bold', fontSize: 9, lineHeight: 12, color: colors.blueDark, letterSpacing: 0.7 },
  calendarDay: { marginTop: 1, fontFamily: 'Montserrat_800ExtraBold', fontSize: 23, lineHeight: 28, color: colors.ink },
  upcomingTitle: { marginTop: 7, fontFamily: 'Montserrat_700Bold', fontSize: 13, lineHeight: 19, color: colors.ink },
  upcomingBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 16, color: colors.muted },
  helpStrip: { marginTop: 24, borderRadius: 18, backgroundColor: colors.bluePale, padding: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  helpIcon: { width: 43, height: 43, borderRadius: 15, backgroundColor: colors.surface, alignItems: 'center', justifyContent: 'center' },
  helpTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 13, lineHeight: 18, color: colors.ink },
  helpBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 16, color: colors.muted },
  previewNotice: { marginTop: 24, flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'center', gap: 7, paddingHorizontal: 12 },
  previewNoticeText: { flexShrink: 1, fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 15, color: colors.gold, textAlign: 'center' },
  filterRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 20 },
  filterChip: { minHeight: 40, borderRadius: 99, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, paddingHorizontal: 15, alignItems: 'center', justifyContent: 'center' },
  filterChipActive: { backgroundColor: colors.ink, borderColor: colors.ink },
  filterChipText: { fontFamily: 'Montserrat_600SemiBold', fontSize: 11, lineHeight: 15, color: colors.muted },
  filterChipTextActive: { color: colors.surface },
  electionList: { gap: 14 },
  electionCard: { borderRadius: 21, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, padding: 18, ...shadows.card },
  electionCardTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  electionDate: { fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 14, color: colors.muted },
  electionTitle: { marginTop: 18, fontFamily: 'Montserrat_700Bold', fontSize: 18, lineHeight: 25, color: colors.ink, letterSpacing: -0.35 },
  electionDescription: { marginTop: 6, maxWidth: 640, fontFamily: 'Montserrat_400Regular', fontSize: 12, lineHeight: 19, color: colors.muted },
  electionMetaRow: { marginTop: 14, flexDirection: 'row', alignItems: 'center', gap: 6 },
  electionMeta: { fontFamily: 'Montserrat_500Medium', fontSize: 11, lineHeight: 16, color: colors.muted },
  electionCardFooter: { marginTop: 17, paddingTop: 14, borderTopWidth: 1, borderTopColor: colors.border, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  electionTiming: { flex: 1, fontFamily: 'Montserrat_700Bold', fontSize: 11, lineHeight: 16, color: colors.blueDark },
  circleArrow: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bluePale },
  cardPressed: { transform: [{ scale: 0.993 }], opacity: 0.88 },
  resultsHero: { padding: 20 },
  resultsTopRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  resultsTimestamp: { fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 14, color: colors.muted },
  resultsElection: { marginTop: 20, fontFamily: 'Montserrat_800ExtraBold', fontSize: 20, lineHeight: 27, color: colors.ink, letterSpacing: -0.45 },
  resultsContest: { marginTop: 4, fontFamily: 'Montserrat_400Regular', fontSize: 12, lineHeight: 18, color: colors.muted },
  turnoutRow: { marginTop: 21, borderRadius: 17, backgroundColor: colors.surfaceMuted, padding: 15, flexDirection: 'row', alignItems: 'center' },
  turnoutStat: { flex: 1, alignItems: 'center' },
  turnoutNumber: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 20, lineHeight: 27, color: colors.ink },
  turnoutLabel: { marginTop: 2, fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 14, color: colors.muted },
  turnoutDivider: { width: 1, height: 38, backgroundColor: colors.border },
  resultRows: { marginTop: 16, gap: 12 },
  resultCard: { padding: 16 },
  resultIdentity: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  rankTile: { width: 38, height: 38, borderRadius: 13, backgroundColor: colors.surfaceMuted, alignItems: 'center', justifyContent: 'center' },
  rankTileLeader: { backgroundColor: colors.tealPale },
  rankText: { fontFamily: 'Montserrat_700Bold', fontSize: 14, lineHeight: 19, color: colors.muted },
  rankTextLeader: { color: colors.teal },
  resultNameRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 7 },
  resultName: { fontFamily: 'Montserrat_700Bold', fontSize: 14, lineHeight: 20, color: colors.ink },
  resultParty: { marginTop: 2, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 15, color: colors.muted },
  resultPercent: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 16, lineHeight: 22, color: colors.ink },
  resultTrack: { marginTop: 16, height: 8, borderRadius: 99, overflow: 'hidden', backgroundColor: colors.border },
  resultFill: { height: '100%', borderRadius: 99 },
  resultVotes: { marginTop: 7, fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 14, color: colors.muted, textAlign: 'right' },
  integrityNote: { marginTop: 18, borderRadius: 17, backgroundColor: colors.bluePale, padding: 15, flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  integrityTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  integrityBody: { marginTop: 4, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 17, color: colors.muted },
  titleWithAction: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 },
  listGroupTitle: { marginBottom: 10, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark, letterSpacing: 1 },
  updateCard: { marginBottom: 11, borderRadius: 19, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, padding: 15, flexDirection: 'row', alignItems: 'flex-start', gap: 13 },
  updateCardUnread: { borderColor: colors.blueSoft, backgroundColor: '#FBFCFF' },
  updateIcon: { width: 44, height: 44, borderRadius: 15, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.surfaceMuted },
  updateIconUnread: { backgroundColor: colors.bluePale },
  updateTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  updateTitle: { flex: 1, fontFamily: 'Montserrat_700Bold', fontSize: 13, lineHeight: 19, color: colors.ink },
  updateUnreadDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: colors.blue },
  updateBody: { marginTop: 5, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 17, color: colors.muted },
  updateTime: { marginTop: 8, fontFamily: 'Montserrat_600SemiBold', fontSize: 9, lineHeight: 13, color: colors.subtle },
  privacyStrip: { marginTop: 13, borderRadius: 17, backgroundColor: colors.tealPale, padding: 15, flexDirection: 'row', alignItems: 'center', gap: 10 },
  privacyStripText: { flex: 1, fontFamily: 'Montserrat_500Medium', fontSize: 11, lineHeight: 17, color: colors.ink },
  profileCard: { padding: 20, alignItems: 'center' },
  profileAvatar: { width: 76, height: 76, borderRadius: 26, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bluePale },
  profileAvatarText: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 20, lineHeight: 27, color: colors.blueDark },
  verifiedTick: { position: 'absolute', right: -2, bottom: -2, width: 24, height: 24, borderRadius: 12, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.teal, borderWidth: 3, borderColor: colors.surface },
  profileName: { marginTop: 14, fontFamily: 'Montserrat_800ExtraBold', fontSize: 20, lineHeight: 27, color: colors.ink },
  profileEmail: { marginTop: 3, marginBottom: 12, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 16, color: colors.muted },
  profileReference: { marginTop: 17, width: '100%', borderRadius: 15, backgroundColor: colors.surfaceMuted, padding: 13, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  profileRefLabel: { fontFamily: 'Montserrat_700Bold', fontSize: 9, lineHeight: 13, color: colors.subtle, letterSpacing: 0.7 },
  profileRefValue: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  settingsGroupTitle: { marginTop: 27, marginBottom: 10, fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  settingBlock: { padding: 15 },
  settingLabelRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  settingRow: { minHeight: 74, padding: 15, flexDirection: 'row', alignItems: 'center', gap: 12 },
  settingIcon: { width: 40, height: 40, borderRadius: 14, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bluePale },
  settingTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  settingBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 15, color: colors.muted },
  sizeOptions: { marginTop: 13, flexDirection: 'row', gap: 8 },
  sizeOption: { flex: 1, minHeight: 42, borderRadius: 13, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surfaceMuted, alignItems: 'center', justifyContent: 'center' },
  sizeOptionActive: { borderColor: colors.blue, backgroundColor: colors.bluePale },
  sizeOptionText: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.muted },
  sizeOptionTextActive: { color: colors.blueDark },
  versionText: { marginTop: 22, fontFamily: 'Montserrat_500Medium', fontSize: 9, lineHeight: 14, color: colors.subtle, textAlign: 'center' },
  pressOpacity: { opacity: 0.68 },
  ballotPage: { flex: 1, backgroundColor: colors.canvas },
  ballotHeaderWrap: { backgroundColor: colors.surface, zIndex: 2 },
  ballotHeader: { minHeight: 72, borderBottomWidth: 1, borderBottomColor: colors.border, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', gap: 10 },
  ballotHeaderSpacer: { width: 46 },
  ballotHeaderTitleWrap: { flex: 1, alignItems: 'center', minWidth: 0 },
  ballotHeaderEyebrow: { fontFamily: 'Montserrat_700Bold', fontSize: 8, lineHeight: 11, color: colors.blueDark, letterSpacing: 0.9 },
  ballotHeaderTitle: { marginTop: 2, maxWidth: '100%', fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  ballotProgressTrack: { height: 5, backgroundColor: colors.blueSoft },
  ballotProgressFill: { height: '100%', backgroundColor: colors.blue },
  ballotIntroContent: { width: '100%', maxWidth: 670, alignSelf: 'center', paddingHorizontal: 20, paddingTop: 30, paddingBottom: 38, alignItems: 'center' },
  ballotIntroIcon: { width: 64, height: 64, borderRadius: 22, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  ballotIntroTitle: { marginTop: 17, fontFamily: 'Montserrat_800ExtraBold', fontSize: 27, lineHeight: 35, color: colors.ink, letterSpacing: -0.75, textAlign: 'center' },
  ballotIntroBody: { marginTop: 6, fontFamily: 'Montserrat_500Medium', fontSize: 13, lineHeight: 19, color: colors.muted, textAlign: 'center' },
  ballotFacts: { marginTop: 21, width: '100%', flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 8 },
  ballotFact: { minHeight: 38, borderRadius: 99, backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.border, paddingHorizontal: 11, flexDirection: 'row', alignItems: 'center', gap: 6 },
  ballotFactText: { fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 14, color: colors.ink },
  beforePanel: { marginTop: 23, width: '100%', padding: 17 },
  beforeTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 15, lineHeight: 21, color: colors.ink },
  beforeRow: { marginTop: 16, flexDirection: 'row', alignItems: 'flex-start', gap: 11 },
  beforeIcon: { width: 36, height: 36, borderRadius: 12, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  beforeRowTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  beforeRowBody: { marginTop: 2, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 16, color: colors.muted },
  ballotCallout: { marginTop: 15, marginBottom: 20, width: '100%', borderRadius: 16, backgroundColor: colors.tealPale, padding: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 9 },
  ballotCalloutText: { flex: 1, fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 16, color: colors.ink },
  howLink: { minHeight: 46, marginTop: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7, paddingHorizontal: 10 },
  howLinkText: { fontFamily: 'Montserrat_700Bold', fontSize: 11, lineHeight: 16, color: colors.blueDark },
  contestContent: { width: '100%', maxWidth: 720, alignSelf: 'center', paddingHorizontal: 20, paddingTop: 26, paddingBottom: 170 },
  contestTopline: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  contestNumber: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark, letterSpacing: 1 },
  contestTitle: { marginTop: 14, fontFamily: 'Montserrat_800ExtraBold', fontSize: 27, lineHeight: 36, color: colors.ink, letterSpacing: -0.75 },
  contestInstructions: { marginTop: 7, fontFamily: 'Montserrat_400Regular', fontSize: 13, lineHeight: 21, color: colors.muted },
  choiceList: { marginTop: 19, gap: 12 },
  choiceCard: { borderRadius: 19, backgroundColor: colors.surface, borderWidth: 1.5, borderColor: colors.border, overflow: 'hidden' },
  choiceCardSelected: { borderColor: colors.blue, backgroundColor: '#FBFCFF' },
  choiceSelectArea: { minHeight: 83, padding: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  candidateInitials: { width: 48, height: 48, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
  candidateInitialsText: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 14, lineHeight: 19 },
  choiceName: { fontFamily: 'Montserrat_700Bold', fontSize: 13, lineHeight: 19, color: colors.ink },
  choiceParty: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 15, color: colors.muted },
  radioOuter: { width: 24, height: 24, borderRadius: 12, borderWidth: 2, borderColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center' },
  radioOuterSelected: { borderColor: colors.blue },
  radioInner: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.blue },
  detailsLink: { minHeight: 45, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 7 },
  detailsLinkText: { flex: 1, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark },
  skipConfirmation: { marginTop: 13, borderRadius: 14, backgroundColor: colors.goldPale, padding: 12, flexDirection: 'row', alignItems: 'center', gap: 8 },
  skipConfirmationText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 15, color: colors.gold },
  equalTreatmentNote: { marginTop: 17, fontFamily: 'Montserrat_400Regular', fontSize: 9, lineHeight: 15, color: colors.subtle, textAlign: 'center' },
  ballotFooter: { position: 'absolute', left: 0, right: 0, bottom: 0, borderTopWidth: 1, borderTopColor: colors.border, backgroundColor: colors.surface, paddingHorizontal: 16, paddingTop: 12, paddingBottom: Platform.OS === 'ios' ? 22 : 14, ...shadows.card },
  ballotFooterInner: { width: '100%', maxWidth: 680, alignSelf: 'center' },
  skipLink: { minHeight: 42, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12 },
  skipLinkText: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 15, color: colors.blueDark },
  reviewContent: { width: '100%', maxWidth: 720, alignSelf: 'center', paddingHorizontal: 20, paddingTop: 26, paddingBottom: 42 },
  reviewTitle: { marginTop: 12, fontFamily: 'Montserrat_800ExtraBold', fontSize: 27, lineHeight: 36, color: colors.ink, letterSpacing: -0.75 },
  reviewBody: { marginTop: 7, fontFamily: 'Montserrat_400Regular', fontSize: 13, lineHeight: 21, color: colors.muted },
  undervoteWarning: { marginTop: 17, borderRadius: 16, backgroundColor: colors.goldPale, padding: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 9 },
  undervoteWarningText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 16, color: colors.gold },
  reviewList: { marginTop: 20, gap: 11 },
  reviewCard: { overflow: 'hidden' },
  reviewCardTop: { minHeight: 92, padding: 15, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  reviewNumber: { width: 34, height: 34, borderRadius: 12, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  reviewNumberText: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.blueDark },
  reviewContest: { fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 15, color: colors.muted },
  reviewChoice: { marginTop: 5, fontFamily: 'Montserrat_700Bold', fontSize: 14, lineHeight: 20, color: colors.ink },
  reviewChoiceBlank: { color: colors.gold },
  reviewParty: { marginTop: 2, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 15, color: colors.muted },
  changeButton: { minHeight: 44, borderTopWidth: 1, borderTopColor: colors.border, paddingHorizontal: 15, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7 },
  changeButtonText: { fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 14, color: colors.blueDark },
  reviewCheck: { marginTop: 20, marginBottom: 16, borderRadius: 17, borderWidth: 1, borderColor: colors.borderStrong, backgroundColor: colors.surface, padding: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 11 },
  checkBox: { width: 24, height: 24, borderRadius: 7, borderWidth: 2, borderColor: colors.borderStrong, alignItems: 'center', justifyContent: 'center' },
  checkBoxChecked: { backgroundColor: colors.blue, borderColor: colors.blue },
  reviewCheckText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 11, lineHeight: 18, color: colors.ink },
  errorBox: { marginBottom: 16, borderRadius: 16, backgroundColor: colors.redPale, borderWidth: 1, borderColor: '#F2C7C1', padding: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 9 },
  errorTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 11, lineHeight: 16, color: colors.red },
  errorBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 16, color: colors.red },
  castPrivacyText: { marginTop: 10, fontFamily: 'Montserrat_500Medium', fontSize: 9, lineHeight: 14, color: colors.muted, textAlign: 'center' },
  receiptContent: { width: '100%', maxWidth: 660, alignSelf: 'center', paddingHorizontal: 20, paddingTop: 32, paddingBottom: 42, alignItems: 'center' },
  successHalo: { width: 92, height: 92, borderRadius: 46, backgroundColor: colors.tealPale, alignItems: 'center', justifyContent: 'center', marginBottom: 16 },
  successIcon: { width: 62, height: 62, borderRadius: 23, backgroundColor: colors.teal, alignItems: 'center', justifyContent: 'center' },
  receiptTitle: { marginTop: 15, fontFamily: 'Montserrat_800ExtraBold', fontSize: 27, lineHeight: 35, color: colors.ink, letterSpacing: -0.75, textAlign: 'center' },
  receiptBody: { marginTop: 7, maxWidth: 540, fontFamily: 'Montserrat_400Regular', fontSize: 12, lineHeight: 20, color: colors.muted, textAlign: 'center' },
  receiptCard: { marginTop: 23, marginBottom: 14, width: '100%', padding: 17 },
  receiptCardHeader: { paddingBottom: 15, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  receiptLabel: { fontFamily: 'Montserrat_700Bold', fontSize: 9, lineHeight: 13, color: colors.subtle, letterSpacing: 0.8 },
  receiptCode: { marginTop: 4, fontFamily: 'Montserrat_800ExtraBold', fontSize: 21, lineHeight: 28, color: colors.ink, letterSpacing: 0.6 },
  receiptShield: { width: 48, height: 48, borderRadius: 16, backgroundColor: colors.tealPale, alignItems: 'center', justifyContent: 'center' },
  receiptDetail: { minHeight: 36, paddingVertical: 7, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  receiptDetailLabel: { fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 15, color: colors.muted },
  receiptDetailValue: { flexShrink: 1, fontFamily: 'Montserrat_700Bold', fontSize: 10, lineHeight: 15, color: colors.ink, textAlign: 'right' },
  receiptPrivacy: { marginTop: 12, borderRadius: 13, backgroundColor: colors.tealPale, padding: 11, flexDirection: 'row', alignItems: 'center', gap: 8 },
  receiptPrivacyText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 9, lineHeight: 14, color: colors.teal },
  receiptDivider: { width: '100%', height: 1, marginVertical: 15, backgroundColor: colors.border },
  candidateSheetIdentity: { flexDirection: 'row', alignItems: 'center', gap: 13, marginBottom: 22 },
  candidateSheetInitials: { width: 58, height: 58, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  candidateSheetInitialsText: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 17, lineHeight: 23 },
  candidateSheetName: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 18, lineHeight: 25, color: colors.ink },
  candidateSheetParty: { marginTop: 3, fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 15, color: colors.muted },
  sheetSectionTitle: { marginTop: 18, marginBottom: 7, fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  sheetParagraph: { fontFamily: 'Montserrat_400Regular', fontSize: 12, lineHeight: 20, color: colors.muted },
  priorityRow: { minHeight: 36, flexDirection: 'row', alignItems: 'center', gap: 10 },
  priorityBullet: { width: 7, height: 7, borderRadius: 4 },
  priorityText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 11, lineHeight: 17, color: colors.ink },
  neutralityNote: { marginTop: 20, marginBottom: 18, borderRadius: 15, backgroundColor: colors.surfaceMuted, padding: 13, flexDirection: 'row', alignItems: 'flex-start', gap: 8 },
  neutralityText: { flex: 1, fontFamily: 'Montserrat_400Regular', fontSize: 9, lineHeight: 15, color: colors.muted },
  sheetLead: { marginBottom: 18, fontFamily: 'Montserrat_400Regular', fontSize: 13, lineHeight: 21, color: colors.muted },
  supportOption: { minHeight: 72, marginBottom: 10, borderRadius: 17, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface, padding: 13, flexDirection: 'row', alignItems: 'center', gap: 11 },
  supportOptionIcon: { width: 42, height: 42, borderRadius: 14, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  supportOptionTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  supportOptionBody: { marginTop: 2, fontFamily: 'Montserrat_400Regular', fontSize: 9, lineHeight: 14, color: colors.muted },
  supportPrivacy: { marginTop: 8, marginBottom: 18, borderRadius: 15, backgroundColor: colors.tealPale, padding: 13, flexDirection: 'row', alignItems: 'flex-start', gap: 9 },
  supportPrivacyText: { flex: 1, fontFamily: 'Montserrat_500Medium', fontSize: 10, lineHeight: 16, color: colors.ink },
  securityStep: { marginBottom: 15, flexDirection: 'row', alignItems: 'flex-start', gap: 11 },
  securityStepIcon: { width: 39, height: 39, borderRadius: 14, backgroundColor: colors.tealPale, alignItems: 'center', justifyContent: 'center' },
  securityStepTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 12, lineHeight: 17, color: colors.ink },
  securityStepBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 10, lineHeight: 16, color: colors.muted },
  securityCaution: { marginTop: 5, marginBottom: 18, borderRadius: 15, backgroundColor: colors.goldPale, padding: 13 },
  securityCautionTitle: { fontFamily: 'Montserrat_700Bold', fontSize: 11, lineHeight: 16, color: colors.gold },
  securityCautionBody: { marginTop: 3, fontFamily: 'Montserrat_400Regular', fontSize: 9, lineHeight: 15, color: colors.gold },
  numberedStep: { marginBottom: 18, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  numberedStepNumber: { width: 38, height: 38, borderRadius: 14, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  numberedStepNumberText: { fontFamily: 'Montserrat_800ExtraBold', fontSize: 13, lineHeight: 18, color: colors.blueDark },
  receiptExplainIcon: { width: 60, height: 60, borderRadius: 21, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center', marginBottom: 16 },
  electionSheetTitle: { marginTop: 15, marginBottom: 7, fontFamily: 'Montserrat_800ExtraBold', fontSize: 21, lineHeight: 29, color: colors.ink, letterSpacing: -0.45 },
  electionSheetFacts: { marginTop: 18, padding: 13 },
  reminderNote: { marginTop: 15, marginBottom: 18, borderRadius: 15, backgroundColor: colors.bluePale, padding: 13, flexDirection: 'row', alignItems: 'center', gap: 9 },
  reminderNoteText: { flex: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 10, lineHeight: 16, color: colors.ink },
  confirmScrim: { flex: 1, backgroundColor: colors.scrim, padding: 20, alignItems: 'center', justifyContent: 'center' },
  confirmDialog: { width: '100%', maxWidth: 450, borderRadius: 25, backgroundColor: colors.surface, padding: 22, alignItems: 'center', ...shadows.floating },
  confirmIcon: { width: 60, height: 60, borderRadius: 21, backgroundColor: colors.bluePale, alignItems: 'center', justifyContent: 'center' },
  confirmTitle: { marginTop: 15, fontFamily: 'Montserrat_800ExtraBold', fontSize: 21, lineHeight: 29, color: colors.ink, textAlign: 'center' },
  confirmBody: { marginTop: 7, fontFamily: 'Montserrat_400Regular', fontSize: 11, lineHeight: 18, color: colors.muted, textAlign: 'center' },
  confirmWarning: { width: '100%', marginTop: 16, marginBottom: 17, borderRadius: 14, backgroundColor: colors.goldPale, padding: 11, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7 },
  confirmWarningText: { flexShrink: 1, fontFamily: 'Montserrat_600SemiBold', fontSize: 9, lineHeight: 14, color: colors.gold, textAlign: 'center' },
  confirmCancel: { width: '100%', marginTop: 9 },
});
