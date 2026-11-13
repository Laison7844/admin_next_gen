/// Default initial content templates matching the live NextGen website audit.
class HomeDefaultData {
  // 1. Hero
  static const Map<String, dynamic> hero = {
    'subTagline': 'A New Beginning. A Brighter Tomorrow.',
    'mainTitle': 'Building Strong Foundations for',
    'highlightedTitle': 'Lifelong Success',
    'description':
        'At NextGen, we focus on concept clarity, confidence and character — nurturing every child to reach their full potential.',
    'primaryButtonLabel': 'Explore Programs',
    'secondaryButtonLabel': 'Contact Us',
    'heroImage': 'assets/images/hero_student.webp',
    'featureChips': [
      {'title': '1 to 10 All Subjects', 'subtitle': 'Classes 1 - 10'},
      {'title': 'Online & Offline', 'subtitle': 'Flexible Batches'},
      {'title': '1-1 Special Care', 'subtitle': 'Personalized'},
    ],
  };

  // 2. Feature Highlights (Six Pillars under Hero)
  static const List<Map<String, dynamic>> featureHighlights = [
    {
      'id': 'feat_personalized',
      'title': 'Personalized Learning',
      'description': '1-1 special attention for every student.',
      'icon': 'groups_outlined',
      'order': 1,
      'isVisible': true,
    },
    {
      'id': 'feat_expert',
      'title': 'Expert Guidance',
      'description': 'Passionate teachers who care.',
      'icon': 'person_search_outlined',
      'order': 2,
      'isVisible': true,
    },
    {
      'id': 'feat_tests',
      'title': 'Weekly & Monthly Tests',
      'description': 'Regular assessments for better results.',
      'icon': 'edit_calendar_outlined',
      'order': 3,
      'isVisible': true,
    },
    {
      'id': 'feat_parent_updates',
      'title': 'Regular Parent Updates',
      'description': "Stay informed about your child's progress.",
      'icon': 'notifications_none_outlined',
      'order': 4,
      'isVisible': true,
    },
    {
      'id': 'feat_safe_env',
      'title': 'Safe & Supportive Environment',
      'description': 'A positive place to learn and grow.',
      'icon': 'verified_user_outlined',
      'order': 5,
      'isVisible': true,
    },
    {
      'id': 'feat_concept_focus',
      'title': 'Focused on Concepts',
      'description': 'Clarity today, confidence forever.',
      'icon': 'star_outline_rounded',
      'order': 6,
      'isVisible': true,
    },
  ];

  // 3. About Us
  static const Map<String, dynamic> about = {
    'category': 'ABOUT NEXTGEN EXCELLENCE ACADEMY',
    'title': 'Inspiring Young Minds with Knowledge, Values & Confidence',
    'description':
        'NextGen Excellence Academy was founded to nurture foundational excellence in young learners through individual care, concept clarity, and interactive teaching methods.',
    'pillars': [
      {
        'title': 'Concept-Based Learning',
        'description':
            'Moving away from rote memorization to foster deep understanding of core concepts in every subject.',
        'icon': 'psychology_rounded',
      },
      {
        'title': 'Individual Attention',
        'description':
            'Small batch sizes ensure every child feels heard, supported, and guided through every topic.',
        'icon': 'record_voice_over_rounded',
      },
      {
        'title': 'Friendly Environment',
        'description':
            'Caring faculty dedicated to creating a safe, encouraging, and stress-free learning space.',
        'icon': 'sentiment_very_satisfied_rounded',
      },
      {
        'title': 'Continuous Progress',
        'description':
            'Regular evaluations, weekly tests, and parent updates for transparent growth tracking.',
        'icon': 'auto_graph_rounded',
      },
    ],
  };

  // 4. Default Courses
  static const List<Map<String, dynamic>> defaultCourses = [
    {
      'id': 'course_classes_1_7',
      'title': 'Classes 1 – 7',
      'subtitle': 'All Subjects Tuition',
      'tag': 'Foundation',
      'description':
          'Strong foundation in all subjects for a bright future. Focus on basics, reading comprehension, and problem solving.',
      'icon': 'menu_book_rounded',
      'highlights': [
        'Mathematics, Science, English, & Regional Languages',
        'Daily homework assistance & concept building',
        'Fun activity-based teaching methods',
        'Weekly review quizzes',
      ],
      'order': 1,
      'isVisible': true,
      'isFeatured': true,
    },
    {
      'id': 'course_classes_8_10',
      'title': 'Classes 8 – 10',
      'subtitle': 'Special Tuition',
      'tag': 'Secondary',
      'description':
          'Concept-based learning & exam-focused preparation. Targeted coaching for board excellence and clarity.',
      'icon': 'school_rounded',
      'highlights': [
        'In-depth Physics, Chemistry, Biology & Maths',
        'Board exam strategies & sample paper solving',
        'Doubt clearing sessions after every chapter',
        'Individual performance tracking',
      ],
      'order': 2,
      'isVisible': true,
      'isFeatured': true,
    },
    {
      'id': 'course_computer_tuition',
      'title': 'Computer Tuition',
      'subtitle': 'Digital & Practical Skills',
      'tag': 'Skill Build',
      'description':
          'Basics to Advanced Computer Education, Coding fundamentals, and essential digital productivity skills.',
      'icon': 'desktop_windows_rounded',
      'highlights': [
        'Computer fundamentals & OS navigation',
        'MS Office, Typing mastery & Internet safety',
        'Basic programming & logic building',
        'Hands-on lab assignments',
      ],
      'order': 3,
      'isVisible': true,
      'isFeatured': true,
    },
  ];

  // 5. Default Special Programs
  static const List<Map<String, dynamic>> defaultPrograms = [
    {
      'id': 'prog_spoken_english',
      'title': 'Spoken English & Grammar',
      'subtitle': 'Fluent & Confident Communication',
      'tag': 'Communication',
      'description':
          'Interactive English speaking and comprehensive grammar coaching designed to eliminate hesitation.',
      'icon': 'record_voice_over_rounded',
      'highlights': [
        'Vocabulary building & active conversation practice',
        'Grammar drills & pronunciation correction',
        'Public speaking & presentation sessions',
        'Confidence-building activities',
      ],
      'order': 1,
      'isVisible': true,
      'isFeatured': true,
    },
    {
      'id': 'prog_handwriting',
      'title': 'Handwriting Improvement',
      'subtitle': 'Neat, Fast & Legible Writing',
      'tag': 'Special Care',
      'description':
          'Scientifically designed techniques to improve cursive and print handwriting, pencil grip, speed, and overall exam presentation.',
      'icon': 'edit_note_rounded',
      'highlights': [
        'Stroke correction & letter spacing techniques',
        'Speed writing drills for school exams',
        'Posture and grip correction',
        'Cursive and print style mastery',
      ],
      'order': 2,
      'isVisible': true,
      'isFeatured': true,
    },
    {
      'id': 'prog_abacus',
      'title': 'Abacus & Mental Math',
      'subtitle': 'Sharp Mind & Speed Calculation',
      'tag': 'Brain Dev',
      'description':
          'Boost concentration, memory, calculation speed, and mental agility through structured Abacus training.',
      'icon': 'calculate_rounded',
      'highlights': [
        'Speed arithmetic without calculators',
        'Visual memory & focus enhancement',
        'Confidence in school math competitions',
        'Age-appropriate graded levels',
      ],
      'order': 3,
      'isVisible': true,
      'isFeatured': true,
    },
    {
      'id': 'prog_1_to_1_care',
      'title': '1-to-1 Special Care',
      'subtitle': 'Personalized Mentor Attention',
      'tag': 'Individual Care',
      'description':
          'Dedicated single-student coaching tailored for students needing extra time, special guidance, or advanced acceleration.',
      'icon': 'star_rounded',
      'highlights': [
        'Single-student dedicated mentor',
        'Customized syllabus & pacing',
        'Bridge learning gaps thoroughly',
        'Flexible batch timings',
      ],
      'order': 4,
      'isVisible': true,
      'isFeatured': true,
    },
  ];

  // 6. Why NextGen
  static const Map<String, dynamic> whyNextGen = {
    'title': 'Why Choose NextGen Excellence Academy?',
    'subtitle': 'The NextGen Difference',
    'reasons': [
      'Concept clarity through simple explanations',
      'Small batch size for individual attention',
      'Doubt clearing sessions & extra practice',
      'Focus on values, discipline & confidence',
      'Affordable fees with quality education',
      'Friendly faculty & caring learning environment',
    ],
  };

  // 7. Learning Modes
  static const Map<String, dynamic> learningModes = {
    'modes': [
      {
        'title': 'Interactive Offline Classes',
        'badge': 'Campus Experience',
        'description':
            'Face-to-face tuition in a supportive, comfortable classroom with direct teacher interaction and hands-on exercises.',
        'icon': 'business_outlined',
        'image': 'assets/images/classroom_students.webp',
      },
      {
        'title': 'Live Online Classes',
        'badge': 'Learn from Home',
        'description':
            'Interactive live sessions with screen sharing, digital whiteboard, and recorded backups for complete revision flexibility.',
        'icon': 'devices_outlined',
        'image': 'assets/images/online_learning.webp',
      },
    ],
  };

  // 8. Pledge
  static const Map<String, dynamic> pledge = {
    'category': 'OUR COMMITMENT & VALUES',
    'title': 'The NextGen Excellence Pledge',
    'subtitle':
        'Our solemn commitment to every student and parent — fostering conceptual clarity, individual care, character, and lifelong confidence.',
    'pledgeDocumentImage': 'assets/images/pledge_next_gen.webp',
  };

  // 9. Assessments & Progress
  static const Map<String, dynamic> assessments = {
    'category': 'ASSESSMENTS & PROGRESS',
    'title': 'Structured Evaluation & Academic Tracking',
    'subtitle':
        'Continuous evaluation ensuring every concept is thoroughly understood and mastered.',
    'evaluationCards': [
      {
        'title': 'Weekly Tests',
        'subtitle': 'Regular weekly assessments to monitor continuous progress.',
        'icon': 'assignment_outlined',
      },
      {
        'title': 'Monthly Exams',
        'subtitle': 'Comprehensive chapter-wise exams for exam readiness.',
        'icon': 'calendar_month_outlined',
      },
      {
        'title': 'Revision Sessions',
        'subtitle': 'Dedicated recap sessions to reinforce core concepts.',
        'icon': 'replay_circle_filled_outlined',
      },
      {
        'title': 'Progress Reports',
        'subtitle': 'Detailed individual reports shared with parents.',
        'icon': 'assessment_outlined',
      },
      {
        'title': 'Parent Feedback Meetings',
        'subtitle':
            'One-on-one parent interaction for collaborative student support.',
        'icon': 'groups_outlined',
      },
    ],
  };

  // 10. Banner CTA
  static const Map<String, dynamic> bannerCta = {
    'mainHeading': 'Give Your Child the Advantage of',
    'highlightedHeading': 'Concept Clarity & Confidence',
    'badges': [
      'Admissions Open for Classes 1 – 10',
      'Limited Batch Sizes',
      'Free Counseling Available',
    ],
    'buttonLabel': 'Enquire Now',
  };

  // 11. Gallery Default Items
  static const List<Map<String, dynamic>> defaultGallery = [
    {
      'id': 'gal_interactive_classroom',
      'title': 'Interactive Classroom Sessions',
      'category': 'Classroom',
      'description':
          'Students actively engaged in concept learning and group problem solving.',
      'image': 'assets/images/classroom_students.webp',
      'order': 1,
      'isVisible': true,
    },
    {
      'id': 'gal_1to1_mentorship',
      'title': '1-to-1 Mentorship in Action',
      'category': 'Special Care',
      'description':
          'Personalized guidance helping students grasp difficult topics at their own pace.',
      'image': 'assets/images/special_care.webp',
      'order': 2,
      'isVisible': true,
    },
    {
      'id': 'gal_computer_education',
      'title': 'Practical Computer Education',
      'category': 'Computer Lab',
      'description':
          'Hands-on computer training in a safe, guided and encouraging setup.',
      'image': 'assets/images/computer_tuition.webp',
      'order': 3,
      'isVisible': true,
    },
    {
      'id': 'gal_weekend_batches',
      'title': 'Special Weekend Batches',
      'category': 'Activities',
      'description':
          'Specialized classes in handwriting improvement, mental math, and spoken English.',
      'image': 'assets/images/special_classes.webp',
      'order': 4,
      'isVisible': true,
    },
  ];

  // 12. Default FAQs
  static const List<Map<String, dynamic>> defaultFaqs = [
    {
      'id': 'faq_classes_subjects',
      'question':
          'What classes and subjects are covered at NextGen Excellence Academy?',
      'answer':
          'We offer comprehensive tuition for Classes 1 to 7 (All Subjects) and Classes 8 to 10 (Specialized Science, Maths, English & Social Science), as well as Computer Tuition, Spoken English, Handwriting Improvement, and Abacus.',
      'category': 'General',
      'order': 1,
      'isVisible': true,
    },
    {
      'id': 'faq_batch_size',
      'question': 'What is the batch size at NextGen?',
      'answer':
          'We strictly maintain small batch sizes to ensure every student receives individual attention, active participation opportunities, and personalized feedback.',
      'category': 'Batches',
      'order': 2,
      'isVisible': true,
    },
    {
      'id': 'faq_special_care',
      'question': 'How do 1-to-1 Special Care sessions work?',
      'answer':
          'In 1-to-1 sessions, a dedicated mentor works exclusively with the student to address specific learning difficulties, bridge knowledge gaps, and build confidence at their custom pace.',
      'category': 'Learning',
      'order': 3,
      'isVisible': true,
    },
    {
      'id': 'faq_modes',
      'question': 'Are both Online and Offline modes available?',
      'answer':
          'Yes! We provide interactive in-person classroom tuition as well as live interactive online classes with recorded backup sessions for student convenience.',
      'category': 'Modes',
      'order': 4,
      'isVisible': true,
    },
    {
      'id': 'faq_parent_updates',
      'question': 'How often are parents updated about academic progress?',
      'answer':
          'Parents receive regular updates following weekly tests and monthly examinations, alongside individual parent-teacher progress discussions.',
      'category': 'Updates',
      'order': 5,
      'isVisible': true,
    },
    {
      'id': 'faq_enrollment',
      'question': 'How can I enroll my child or request fee details?',
      'answer':
          'You can call us directly at 8075854535 / 9846256235, fill out the Contact form below, or visit our academy in person for a free counseling session.',
      'category': 'Enrollment',
      'order': 6,
      'isVisible': true,
    },
  ];

  // 13. Contact & Footer
  static const Map<String, dynamic> contactFooter = {
    'phone1': '8075854535',
    'phone2': '9846256235',
    'email': 'nextgenexcellenceacademic@gmail.com',
    'address':
        'Thottakkadu Nagar-41, Thangassery (P.O), Kollam, Kerala, India',
    'brandDescription':
        'NextGen Excellence Academy is dedicated to nurturing foundational excellence in school students through concept clarity, individual care, and inspiring pedagogy.',
    'socialLinks': {
      'facebook': 'https://facebook.com',
      'instagram': 'https://instagram.com',
      'whatsapp': 'https://wa.me/918075854535',
      'youtube': 'https://youtube.com',
    },
    'quickLinks': [
      {'label': 'Home', 'destination': 'home'},
      {'label': 'About Us', 'destination': 'about'},
      {'label': 'Courses', 'destination': 'courses'},
      {'label': 'Programs', 'destination': 'programs'},
      {'label': 'Learning Modes', 'destination': 'modes'},
      {'label': 'Why NextGen?', 'destination': 'why'},
      {'label': 'Admissions Open', 'destination': 'contact'},
    ],
  };
}

