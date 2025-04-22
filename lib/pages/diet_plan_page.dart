import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class DietPlanPage extends StatefulWidget {
  @override
  _DietPlanPageState createState() => _DietPlanPageState();
}

class _DietPlanPageState extends State<DietPlanPage> {
  AIService aiService = AIService();
  String dietPlan = "Fetching diet plan...";
  String userInfo = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String age = prefs.getString('age') ?? "Unknown";
    String height = prefs.getString('height') ?? "Unknown";
    String weight = prefs.getString('weight') ?? "Unknown";
    String goal = prefs.getString('goal') ?? "Unknown";
    String allergies = prefs.getString('allergies') ?? "None";

    setState(() {
      userInfo =
          "Age: $age, Height: $height cm, Weight: $weight kg, Goal: $goal, Allergies: $allergies";
    });

    loadDietPlan();
  }

  // Yeni bir fonksiyon - sadece önbelleğe alınmış planı yükler
  Future<void> loadDietPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedPlan = prefs.getString('dietPlan');

    if (cachedPlan != null) {
      if (mounted) {
        setState(() {
          dietPlan = cachedPlan;
        });
      }
    } else {
      // Önbellekte bir plan yoksa, yeni bir plan oluştur
      fetchDietPlan(forceRegenerate: false);
    }
  }

  // Fonksiyonu yeniden düzenledik - forceRegenerate parametresini ekledik
  Future<void> fetchDietPlan({bool forceRegenerate = true}) async {
    if (isLoading) return; // Zaten yükleniyor ise çıkış yap

    setState(() {
      isLoading = true;
      dietPlan = "Preparing a personalized diet plan...";
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // forceRegenerate true ise veya önbellekte plan yoksa, yeni plan oluştur
    String? cachedPlan = prefs.getString('dietPlan');
    if (!forceRegenerate && cachedPlan != null) {
      if (mounted) {
        setState(() {
          dietPlan = cachedPlan;
          isLoading = false;
        });
      }
      return;
    }

    try {
      // Yeni plan oluştur
      String newPlan = await aiService.generateDietPlan(userInfo);

      if (mounted) {
        setState(() {
          dietPlan = newPlan;
          isLoading = false;
        });
      }

      // SharedPreferences'e kaydet
      await prefs.setString('dietPlan', newPlan);
    } catch (e) {
      if (mounted) {
        setState(() {
          dietPlan = "Error generating diet plan: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed:
                  isLoading ? null : () => fetchDietPlan(forceRegenerate: true),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text("Generating...")
                      ],
                    )
                  : Text("Regenerate Diet Plan"),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(dietPlan, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
