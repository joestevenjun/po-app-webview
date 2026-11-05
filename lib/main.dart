import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// URL Default jika belum pernah diatur
const String DEFAULT_URL = 'https://bcss.multindo.com/po_mobile/';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PO Approval',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller;
  String currentUrl = DEFAULT_URL;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUrlAndInit();
  }

  // Fungsi untuk memuat URL yang tersimpan, atau pakai default
  Future<void> _loadUrlAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('po_approval_url') ?? DEFAULT_URL;
    
    setState(() {
      currentUrl = savedUrl;
    });
    
    _initController(savedUrl);
  }

  // Fungsi inisialisasi WebView
  void _initController(String url) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => isLoading = progress < 100);
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              errorMessage = 'Gagal memuat halaman:\n${error.description}\n\nPastikan URL benar dan ada koneksi internet.';
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  // Fungsi untuk membuka dialog ganti URL
  Future<void> _showChangeUrlDialog() async {
    final TextEditingController urlController = TextEditingController(text: currentUrl);
    
    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti URL Server'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, urlController.text.trim()),
            child: const Text('Simpan & Muat Ulang'),
          ),
        ],
      ),
    );

    // Jika user memasukkan URL baru dan tidak membatalkan
    if (newUrl != null && newUrl.isNotEmpty) {
      // Simpan ke memori HP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('po_approval_url', newUrl);
      
      // Update tampilan dan reload WebView
      setState(() {
        currentUrl = newUrl;
        isLoading = true;
        errorMessage = null;
      });
      _initController(newUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PO Approval'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Ganti URL (Ikon Gear/Settings)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ganti URL Server',
            onPressed: _showChangeUrlDialog,
          ),
          // Tombol Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Halaman',
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          
          // Loading Indicator
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // Error Screen
          if (errorMessage != null)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                          isLoading = true;
                        });
                        controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showChangeUrlDialog,
                      icon: const Icon(Icons.settings),
                      label: const Text('Ganti URL Server'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
