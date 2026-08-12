import { Ionicons } from '@expo/vector-icons';
import {
  ActivityIndicator,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleProp,
  StyleSheet,
  Text as NativeText,
  TextProps,
  TextStyle,
  View,
  ViewStyle,
} from 'react-native';
import { createContext, ReactNode, useContext } from 'react';
import { colors, shadows } from '../theme/colors';

export type TextSizePreference = 'standard' | 'large' | 'extra-large';

export type AppPreferences = {
  textSize: TextSizePreference;
  highContrast: boolean;
  reduceMotion: boolean;
};

export const PreferencesContext = createContext<AppPreferences>({
  textSize: 'standard',
  highContrast: false,
  reduceMotion: false,
});

export function usePreferences() {
  return useContext(PreferencesContext);
}

const textScale = (preference: TextSizePreference) => {
  if (preference === 'large') return 1.1;
  if (preference === 'extra-large') return 1.2;
  return 1;
};

export function Text({ style, ...props }: TextProps) {
  const { textSize } = usePreferences();
  const flattened = StyleSheet.flatten(style) as TextStyle | undefined;
  const scale = textScale(textSize);
  const scaledStyle: TextStyle | undefined = flattened?.fontSize
    ? {
        fontSize: flattened.fontSize * scale,
        lineHeight: flattened.lineHeight ? flattened.lineHeight * scale : undefined,
      }
    : undefined;

  return <NativeText {...props} allowFontScaling style={[style, scaledStyle]} />;
}

export type IconName = keyof typeof Ionicons.glyphMap;

export function IconButton({
  icon,
  label,
  onPress,
  selected = false,
  tone = 'light',
}: {
  icon: IconName;
  label: string;
  onPress: () => void;
  selected?: boolean;
  tone?: 'light' | 'dark';
}) {
  const dark = tone === 'dark';
  return (
    <Pressable
      accessibilityLabel={label}
      accessibilityRole="button"
      accessibilityState={{ selected }}
      hitSlop={6}
      onPress={onPress}
      style={({ pressed }) => [
        styles.iconButton,
        dark && styles.iconButtonDark,
        selected && styles.iconButtonSelected,
        pressed && styles.pressed,
      ]}>
      <Ionicons
        name={icon}
        size={21}
        color={dark ? colors.surface : selected ? colors.blue : colors.ink}
      />
    </Pressable>
  );
}

export function Badge({
  label,
  tone = 'blue',
  icon,
}: {
  label: string;
  tone?: 'blue' | 'green' | 'gold' | 'neutral' | 'red' | 'purple';
  icon?: IconName;
}) {
  const toneStyle = badgeTones[tone];
  return (
    <View style={[styles.badge, { backgroundColor: toneStyle.background }]}>
      {icon ? <Ionicons name={icon} size={12} color={toneStyle.foreground} /> : null}
      <Text style={[styles.badgeText, { color: toneStyle.foreground }]}>{label}</Text>
    </View>
  );
}

const badgeTones = {
  blue: { background: colors.bluePale, foreground: colors.blueDark },
  green: { background: colors.tealPale, foreground: colors.teal },
  gold: { background: colors.goldPale, foreground: colors.gold },
  neutral: { background: '#EEF1F5', foreground: colors.muted },
  red: { background: colors.redPale, foreground: colors.red },
  purple: { background: colors.lilacPale, foreground: colors.lilac },
};

export function Button({
  label,
  onPress,
  icon,
  variant = 'primary',
  disabled = false,
  loading = false,
  fullWidth = true,
  accessibilityHint,
}: {
  label: string;
  onPress: () => void;
  icon?: IconName;
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  accessibilityHint?: string;
}) {
  const foreground =
    variant === 'primary' || variant === 'danger' ? colors.surface : colors.blueDark;
  return (
    <Pressable
      accessibilityHint={accessibilityHint}
      accessibilityLabel={label}
      accessibilityRole="button"
      accessibilityState={{ disabled, busy: loading }}
      disabled={disabled || loading}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        fullWidth && styles.fullWidth,
        variant === 'primary' && styles.primaryButton,
        variant === 'secondary' && styles.secondaryButton,
        variant === 'ghost' && styles.ghostButton,
        variant === 'danger' && styles.dangerButton,
        (disabled || loading) && styles.buttonDisabled,
        pressed && styles.buttonPressed,
      ]}>
      {loading ? (
        <ActivityIndicator size="small" color={foreground} />
      ) : icon ? (
        <Ionicons name={icon} size={19} color={foreground} />
      ) : null}
      <Text
        style={[
          styles.buttonText,
          (variant === 'secondary' || variant === 'ghost') && styles.secondaryButtonText,
        ]}>
        {label}
      </Text>
    </Pressable>
  );
}

export function Panel({
  children,
  style,
  elevated = false,
}: {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  elevated?: boolean;
}) {
  const { highContrast } = usePreferences();
  return (
    <View
      style={[
        styles.panel,
        highContrast && styles.highContrastPanel,
        elevated && shadows.card,
        style,
      ]}>
      {children}
    </View>
  );
}

export function Divider() {
  const { highContrast } = usePreferences();
  return <View style={[styles.divider, highContrast && styles.dividerHighContrast]} />;
}

export function Sheet({
  visible,
  title,
  onClose,
  children,
}: {
  visible: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
}) {
  const { reduceMotion } = usePreferences();
  return (
    <Modal
      animationType={reduceMotion ? 'none' : 'slide'}
      onRequestClose={onClose}
      transparent
      visible={visible}>
      <View style={styles.scrim}>
        <Pressable
          accessibilityLabel="Close dialog"
          accessibilityRole="button"
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <View accessibilityViewIsModal style={styles.sheet}>
          <View style={styles.sheetHandle} />
          <View style={styles.sheetHeader}>
            <Text accessibilityRole="header" style={styles.sheetTitle}>
              {title}
            </Text>
            <IconButton icon="close" label="Close" onPress={onClose} />
          </View>
          <ScrollView
            bounces={false}
            contentContainerStyle={styles.sheetContent}
            keyboardShouldPersistTaps="handled">
            {children}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

export function EmptyState({
  icon,
  title,
  body,
}: {
  icon: IconName;
  title: string;
  body: string;
}) {
  return (
    <View style={styles.emptyState}>
      <View style={styles.emptyIcon}>
        <Ionicons name={icon} size={28} color={colors.blue} />
      </View>
      <Text style={styles.emptyTitle}>{title}</Text>
      <Text style={styles.emptyBody}>{body}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  iconButton: {
    width: 46,
    height: 46,
    borderRadius: 15,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceMuted,
    borderWidth: 1,
    borderColor: colors.border,
  },
  iconButtonDark: {
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.18)',
  },
  iconButtonSelected: {
    backgroundColor: colors.bluePale,
    borderColor: colors.blueSoft,
  },
  pressed: { opacity: 0.72 },
  badge: {
    alignSelf: 'flex-start',
    minHeight: 26,
    borderRadius: 99,
    paddingHorizontal: 9,
    paddingVertical: 5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  badgeText: {
    fontFamily: 'Montserrat_700Bold',
    fontSize: 10,
    lineHeight: 13,
    letterSpacing: 0.45,
    textTransform: 'uppercase',
  },
  button: {
    minHeight: 52,
    borderRadius: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 9,
  },
  fullWidth: { width: '100%' },
  primaryButton: { backgroundColor: colors.blue },
  secondaryButton: {
    backgroundColor: colors.surface,
    borderWidth: 1.5,
    borderColor: colors.blueSoft,
  },
  ghostButton: { backgroundColor: colors.bluePale },
  dangerButton: { backgroundColor: colors.red },
  buttonDisabled: { opacity: 0.46 },
  buttonPressed: { transform: [{ scale: 0.988 }], opacity: 0.91 },
  buttonText: {
    color: colors.surface,
    fontFamily: 'Montserrat_700Bold',
    fontSize: 14,
    lineHeight: 19,
    textAlign: 'center',
  },
  secondaryButtonText: { color: colors.blueDark },
  panel: {
    backgroundColor: colors.surface,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
  },
  highContrastPanel: { borderColor: colors.ink, borderWidth: 1.5 },
  divider: { height: 1, backgroundColor: colors.border },
  dividerHighContrast: { backgroundColor: colors.ink },
  scrim: {
    flex: 1,
    backgroundColor: colors.scrim,
    justifyContent: 'flex-end',
  },
  sheet: {
    maxHeight: '88%',
    width: '100%',
    maxWidth: 680,
    alignSelf: 'center',
    backgroundColor: colors.surface,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingBottom: Platform.OS === 'ios' ? 30 : 18,
    ...shadows.floating,
  },
  sheetHandle: {
    width: 42,
    height: 4,
    backgroundColor: colors.borderStrong,
    borderRadius: 99,
    alignSelf: 'center',
    marginTop: 10,
  },
  sheetHeader: {
    minHeight: 70,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  sheetTitle: {
    flex: 1,
    fontFamily: 'Montserrat_700Bold',
    fontSize: 20,
    lineHeight: 27,
    color: colors.ink,
  },
  sheetContent: { padding: 20, paddingBottom: 30 },
  emptyState: { alignItems: 'center', paddingVertical: 48, paddingHorizontal: 30 },
  emptyIcon: {
    width: 58,
    height: 58,
    borderRadius: 20,
    backgroundColor: colors.bluePale,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: {
    marginTop: 16,
    fontFamily: 'Montserrat_700Bold',
    fontSize: 17,
    lineHeight: 24,
    color: colors.ink,
    textAlign: 'center',
  },
  emptyBody: {
    marginTop: 6,
    maxWidth: 360,
    fontFamily: 'Montserrat_400Regular',
    fontSize: 14,
    lineHeight: 21,
    color: colors.muted,
    textAlign: 'center',
  },
});
