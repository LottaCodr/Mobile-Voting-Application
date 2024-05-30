import 'package:cloud_firestore/cloud_firestore.dart';

class Candidate {
  final int id;
  final String name;
  final String partyId;
  final String manifesto;
  final String imageUrl;
  int votes;
  bool isVoted;

  Candidate(
      {required this.imageUrl,
      required this.id,
      required this.name,
      required this.partyId,
      this.votes = 0,
      this.isVoted = false,
      required this.manifesto});

  // factory Candidate.fromFirestore(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //   return Candidate(
  //       id: doc.id,
  //       name: data['name'],
  //       partyId: data['partyId'],
  //       manifesto: data['manifesto'],
  //       imageUrl: data['imageUrl']);
  // }
}

final Candidate firstCadidate = Candidate(
    imageUrl: 'assets/imageUrl/Barka.jpeg',
    id: 1,
    name: 'Mr. Barka',
    partyId: 'partyId',
    votes: 263,
    manifesto:
        'Invest in early childhood education programs. Increase access to high-speed internet in rural areas. Provide funding for teacher training and development in technology integration. Equip schools with modern laptops and tablets for students. Offer scholarships and grants for students pursuing STEM careers.');

final Candidate secondCadidate = Candidate(
    imageUrl: 'assets/imageUrl/worthy.jpeg',
    id: 2,
    name: 'Worthy Chukwuemeka',
    partyId: 'partyId',
    votes: 785,
    manifesto:
        'Improve public transportation infrastructure (buses, trains).Invest in renewable energy sources (solar, wind). Implement stricter regulations on pollution control. Increase funding for park maintenance and green spaces. Develop sustainable waste management strategies.');

final Candidate thirdCadidate = Candidate(
    imageUrl: 'assets/imageUrl/Godwin.jpeg',
    id: 3,
    name: 'Jiggy Dan',
    partyId: 'partyId',
    votes: 390,
    manifesto:
        'Expand access to affordable healthcare for all citizens. Reduce wait times for surgeries and specialist appointments. Increase funding for mental health services. Support programs for single mothers and childcare assistance. Invest in initiatives for senior citizen care and support.');

final Candidate fourthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/prince.jpeg',
    id: 4,
    name: 'Prince Prince',
    votes: 979,
    partyId: 'partyId',
    manifesto:
        'Attract new businesses and industries to the region. Offer tax breaks and incentives for small business development. Invest in job training programs for in-demand skills. Support entrepreneurship and innovation initiatives. Reduce regulations and red tape hindering businesses.');

final Candidate fifthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/chris.jpeg',
    id: 5,
    name: 'Chris Rocky',
    partyId: 'partyId',
    votes: 875,
    manifesto:
        'Increase police presence in high-crime neighborhoods. Invest in community policing programs. Implement stricter penalties for violent crimes. Address the root causes of crime through social programs. Focus on rehabilitation and reintegration of offenders.');

final Candidate sixthCadidate = Candidate(
    imageUrl: 'assets/imageUrl/dan.jpeg',
    id: 6,
    name: 'Danjuma Joseph',
    partyId: 'partyId',
    votes: 775,
    manifesto:
        'Increase availability of affordable housing units. Invest in programs to revitalize and improve disadvantaged communities. Improve public transportation infrastructure within cities. Promote mixed-use development projects to create vibrant neighborhoods. Foster a sense of community and belonging through public events and initiatives.');

final Candidate firstCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/Barka.jpeg',
    id: 1,
    name: 'Abbas Danaladi',
    partyId: 'partyId',
    votes: 263,
    manifesto:
        'Invest in early childhood education programs. Increase access to high-speed internet in rural areas. Provide funding for teacher training and development in technology integration. Equip schools with modern laptops and tablets for students. Offer scholarships and grants for students pursuing STEM careers.');

final Candidate secondCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/worthy.jpeg',
    id: 2,
    name: 'Chika Ebube',
    partyId: 'partyId',
    votes: 785,
    manifesto:
        'Improve public transportation infrastructure (buses, trains).Invest in renewable energy sources (solar, wind). Implement stricter regulations on pollution control. Increase funding for park maintenance and green spaces. Develop sustainable waste management strategies.');

final Candidate thirdCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/Godwin.jpeg',
    id: 3,
    name: 'Sofia Yahama',
    partyId: 'partyId',
    votes: 390,
    manifesto:
        'Expand access to affordable healthcare for all citizens. Reduce wait times for surgeries and specialist appointments. Increase funding for mental health services. Support programs for single mothers and childcare assistance. Invest in initiatives for senior citizen care and support.');

final Candidate fourthCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/prince.jpeg',
    id: 4,
    name: 'Osinachi Babalola',
    votes: 979,
    partyId: 'partyId',
    manifesto:
        'Attract new businesses and industries to the region. Offer tax breaks and incentives for small business development. Invest in job training programs for in-demand skills. Support entrepreneurship and innovation initiatives. Reduce regulations and red tape hindering businesses.');

final Candidate fifthCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/chris.jpeg',
    id: 5,
    name: 'Yemi Chukwuka',
    partyId: 'partyId',
    votes: 875,
    manifesto:
        'Increase police presence in high-crime neighborhoods. Invest in community policing programs. Implement stricter penalties for violent crimes. Address the root causes of crime through social programs. Focus on rehabilitation and reintegration of offenders.');

final Candidate sixthCadidateforSenate = Candidate(
    imageUrl: 'assets/imageUrl/dan.jpeg',
    id: 6,
    name: 'Zainab Oche',
    partyId: 'partyId',
    votes: 775,
    manifesto:
        'Increase availability of affordable housing units. Invest in programs to revitalize and improve disadvantaged communities. Improve public transportation infrastructure within cities. Promote mixed-use development projects to create vibrant neighborhoods. Foster a sense of community and belonging through public events and initiatives.');

final Candidate firstCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/Barka.jpeg',
    id: 1,
    name: 'Azaman Buba',
    partyId: 'partyId',
    votes: 263,
    manifesto:
        'Invest in early childhood education programs. Increase access to high-speed internet in rural areas. Provide funding for teacher training and development in technology integration. Equip schools with modern laptops and tablets for students. Offer scholarships and grants for students pursuing STEM careers.');

final Candidate secondCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/worthy.jpeg',
    id: 2,
    name: 'Maimuna Isabella',
    partyId: 'partyId',
    votes: 785,
    manifesto:
        'Improve public transportation infrastructure (buses, trains).Invest in renewable energy sources (solar, wind). Implement stricter regulations on pollution control. Increase funding for park maintenance and green spaces. Develop sustainable waste management strategies.');

final Candidate thirdCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/Godwin.jpeg',
    id: 3,
    name: 'Ben Aflika',
    partyId: 'partyId',
    votes: 390,
    manifesto:
        'Expand access to affordable healthcare for all citizens. Reduce wait times for surgeries and specialist appointments. Increase funding for mental health services. Support programs for single mothers and childcare assistance. Invest in initiatives for senior citizen care and support.');

final Candidate fourthCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/prince.jpeg',
    id: 4,
    name: 'King Konga',
    votes: 979,
    partyId: 'partyId',
    manifesto:
        'Attract new businesses and industries to the region. Offer tax breaks and incentives for small business development. Invest in job training programs for in-demand skills. Support entrepreneurship and innovation initiatives. Reduce regulations and red tape hindering businesses.');

final Candidate fifthCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/chris.jpeg',
    id: 5,
    name: 'Mr. Fibonacci',
    partyId: 'partyId',
    votes: 875,
    manifesto:
        'Increase police presence in high-crime neighborhoods. Invest in community policing programs. Implement stricter penalties for violent crimes. Address the root causes of crime through social programs. Focus on rehabilitation and reintegration of offenders.');

final Candidate sixthCadidateforGov = Candidate(
    imageUrl: 'assets/imageUrl/dan.jpeg',
    id: 6,
    name: 'Christopher Zulala',
    partyId: 'partyId',
    votes: 775,
    manifesto:
        'Increase availability of affordable housing units. Invest in programs to revitalize and improve disadvantaged communities. Improve public transportation infrastructure within cities. Promote mixed-use development projects to create vibrant neighborhoods. Foster a sense of community and belonging through public events and initiatives.');

List<Candidate> myCandidates = [
  firstCadidate,
  secondCadidate,
  thirdCadidate,
  fourthCadidate,
  fifthCadidate,
  sixthCadidate
];
