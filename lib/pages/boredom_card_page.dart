import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:i_am_bored/classes/activity_class.dart';

class BoredomCardPage extends StatefulWidget {
  const BoredomCardPage({Key? key}) : super(key: key);

  @override
  State<BoredomCardPage> createState() => _BoredomCardPageState();
}

class _BoredomCardPageState extends State<BoredomCardPage> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  Activity? currentActivity;
  bool _isLoading = false;
  bool _showingActivity = false; // Track if we're showing activity or card back
  bool _hasGeneratedActivity = false; // Track if we've generated at least one activity

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _resetAppOnStart();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _resetAppOnStart() async {
    // Always reset the entire app state when starting
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_activity');
    await prefs.remove('showing_activity');
    await prefs.remove('has_generated_activity');
    
    // Initialize with clean state
    setState(() {
      currentActivity = null;
      _showingActivity = false;
      _hasGeneratedActivity = false;
    });
    
    // Ensure card is in initial position
    _flipController.reset();
  }

  Future<void> _saveActivityState() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentActivity != null) {
      await prefs.setString(
        'current_activity',
        jsonEncode(currentActivity!.toJson()),
      );
      await prefs.setBool('showing_activity', _showingActivity);
    }
    await prefs.setBool('has_generated_activity', _hasGeneratedActivity);
  }

  // Fallback activities in case API fails
  final List<String> _fallbackActivities = [
    "Take a walk around your neighborhood",
    "Learn a new word in a foreign language",
    "Write in a journal for 10 minutes",
    "Do 10 push-ups or jumping jacks",
    "Call or text a friend you haven't spoken to in a while",
    "Try a new recipe with ingredients you have",
    "Organize one small area of your room",
    "Watch a TED talk on a topic you're curious about",
    "Draw or doodle for 15 minutes",
    "Practice deep breathing or meditation",
    "Read one article about something interesting",
    "Listen to a new song or podcast episode",
    "Take photos of something beautiful around you",
    "Write down 3 things you're grateful for",
    "Learn to fold an origami figure",
    "Do some stretches or yoga poses",
    "Plan your ideal weekend",
    "Research a place you'd like to visit",
    "Try to solve a riddle or brain teaser",
    "Rearrange your workspace or room",
  ];

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });

    // If we have an activity showing, first flip back to the picture card
    if (_showingActivity) {
      await _flipController.reverse();
      setState(() {
        _showingActivity = false;
      });
    }

    try {
      var url = Uri.https('bored-api.appbrewery.com', '/random');

      // Await the http get response, then decode the json-formatted response.
      var response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final activity = Activity.fromJson(data);

        setState(() {
          currentActivity = activity;
          _isLoading = false;
          _showingActivity = true;
          _hasGeneratedActivity = true;
        });
      } else {
        throw Exception('API returned status: ${response.statusCode}');
      }
    } catch (e) {
      // Use fallback activity if API fails
      final random = math.Random();
      final randomActivity =
          _fallbackActivities[random.nextInt(_fallbackActivities.length)];

      setState(() {
        currentActivity = Activity(
          activity: randomActivity,
          availability: 1.0,
          type: "offline",
          participants: 1,
          price: 0.0,
          accessibility: "Low",
          duration: "minutes",
          kidFriendly: true,
          link: "",
          key: "",
        );
        _isLoading = false;
        _showingActivity = true;
        _hasGeneratedActivity = true;
      });

      print('API Error: $e'); // For debugging
    }

    // Flip to show the new activity
    if (currentActivity != null) {
      await _flipController.forward();
      await _saveActivityState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Calculate card dimensions based on 598:813 ratio
    final cardRatio = 598.0 / 813.0; // width/height ratio

    // Adaptive sizing based on orientation and screen size
    double maxWidth, maxHeight;

    if (isLandscape) {
      // In landscape, use more horizontal space but less vertical
      maxWidth = screenSize.width * 0.45;
      maxHeight = screenSize.height * 0.7;
    } else {
      // In portrait, use more vertical space
      maxWidth = screenSize.width * 0.9;
      maxHeight = screenSize.height * 0.6;
    }

    double cardWidth, cardHeight;

    // Determine dimensions while maintaining aspect ratio
    if (maxWidth / maxHeight > cardRatio) {
      // Height is the limiting factor
      cardHeight = maxHeight;
      cardWidth = cardHeight * cardRatio;
    } else {
      // Width is the limiting factor
      cardWidth = maxWidth;
      cardHeight = cardWidth / cardRatio;
    }

    // Ensure minimum readable size
    if (cardWidth < 280) {
      cardWidth = 280;
      cardHeight = cardWidth / cardRatio;
    }

    // Calculate responsive font sizes
    final baseFontSize = cardWidth * 0.055;
    final titleFontSize = (baseFontSize * 1.2).clamp(16.0, 28.0);
    final bodyFontSize = baseFontSize.clamp(14.0, 24.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boredom Solutions'),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 40.0 : 20.0,
              vertical: isLandscape ? 20.0 : 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top spacing - smaller in landscape
                SizedBox(height: isLandscape ? 20 : 10),

                // Main content in landscape uses Row, portrait uses Column
                if (isLandscape)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card takes left side
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: _buildCard(
                            cardWidth,
                            cardHeight,
                            titleFontSize,
                            bodyFontSize,
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                      // Controls take right side
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: cardHeight * 0.3),
                            _buildControls(
                              isLandscape,
                              titleFontSize,
                              bodyFontSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      // Card
                      _buildCard(
                        cardWidth,
                        cardHeight,
                        titleFontSize,
                        bodyFontSize,
                      ),
                      SizedBox(height: 20),
                      // Controls
                      _buildControls(isLandscape, titleFontSize, bodyFontSize),
                    ],
                  ),

                SizedBox(height: isLandscape ? 20 : 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    double cardWidth,
    double cardHeight,
    double titleFontSize,
    double bodyFontSize,
  ) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isShowingFront = _flipAnimation.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * math.pi),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child:
                isShowingFront
                    ? _buildFrontCard(
                      cardWidth,
                      cardHeight,
                      titleFontSize,
                      bodyFontSize,
                    )
                    : _buildBackCard(
                      cardWidth,
                      cardHeight,
                      titleFontSize,
                      bodyFontSize,
                    ),
          ),
        );
      },
    );
  }

  Widget _buildControls(
    bool isLandscape,
    double titleFontSize,
    double bodyFontSize,
  ) {
    return Column(
      children: [
        // Button
        ElevatedButton(
          onPressed: _isLoading ? null : getData,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: titleFontSize * 1.5,
              vertical: titleFontSize * 0.8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: Text(
            _hasGeneratedActivity ? 'Find something else' : 'I am bored',
            style: TextStyle(
              fontSize: titleFontSize * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: isLandscape ? 15 : 20),

        // Info text
        Text(
          'Get a random activity suggestion when you\'re feeling bored!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: bodyFontSize * 0.8,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFrontCard(
    double cardWidth,
    double cardHeight,
    double titleFontSize,
    double bodyFontSize,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(cardWidth * 0.06),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/activity_card.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child:
              _isLoading
                  ? CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: cardWidth * 0.01,
                  )
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildBackCard(
    double cardWidth,
    double cardHeight,
    double titleFontSize,
    double bodyFontSize,
  ) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(cardWidth * 0.08),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color.fromARGB(255, 247, 234, 225),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Center(
            child:
                currentActivity != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentActivity!.activity,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : Text(
                      "Press 'I am bored' to get a random activity!",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
          ),
        ),
      ),
    );
  }
}