import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';

import '../../db_helper.dart';
import '../../object-class/local-object-location.dart';
import '../../object-class/local-object-state.dart';

class SFormMarineInvestigateImageRequest extends StatefulWidget {
  _SFormMarineInvestigateImageRequest createState() => _SFormMarineInvestigateImageRequest();
}

class _SFormMarineInvestigateImageRequest extends State<SFormMarineInvestigateImageRequest> {
  // ====== CONFIG: Gmail SMTP (use App Password) ======
  static const String kSmtpEmail = 'pstwitdept@gmail.com';
  static const String kSmtpAppPassword = 'orfovnkgysytzseo'; // replace

  // ====== Connectivity ======
  final Connectivity _connectivity = Connectivity();
  bool _online = true;
  Stream<ConnectivityResult>? _connStream;

  // ====== Filters / State ======
  DateTimeRange? _range;
  List<String> _images = [];
  bool _loading = false;
  String? _error;

  // Category
  late int _selectedItemId = 1;
  Item? selectedItem;
  String? _selectedCategoryKey; // "installation" | "data_collection"

  // Location
  bool _isLocation = false;
  String? stateID;
  String? _selectedStationID;

  // Email + selection
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController(text: 'Requested MMS Images');
  final Set<String> _selectedImages = {};
  bool _sending = false;

  // Map category id -> API key
  final Map<int, String> _categoryKeyMap = const {
    1: 'manual_study_sampling',
  };

  // Category items
  final List<Item> items = const [
    Item(id: 1, categoryName: 'Sampling'),
  ];

  // State/location data
  List<localState> state1 = [];
  localState? selectedLocalState;

  List<localLocation> location1 = [];
  localLocation? selectedLocalLocation;

  // ====== Init loaders ======
  Future<void> _loadState() async {
    final data = await DBHelper.getState();
    setState(() => state1 = data);
  }

  Future<void> _loadLocation(String? stateID) async {
    final data = await DBHelper.getLocationImageMarine(stateID);
    setState(() {
      _isLocation = true;
      location1 = data;
    });
  }

  // ====== Connectivity helpers ======
  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _setOnline(result != ConnectivityResult.none);

    _connStream = _connectivity.onConnectivityChanged;
    _connStream!.listen((status) {
      _setOnline(status != ConnectivityResult.none);
    });
  }

  void _setOnline(bool online) {
    if (mounted && _online != online) {
      setState(() => _online = online);
      if (!online) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
    }
  }

  Future<bool> _hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
    // (If you want to truly verify internet, you could attempt a HEAD to a fast endpoint.)
  }

  // ====== Utilities ======
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isValidEmail(String s) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s.trim());
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
      initialDateRange: initial,
      helpText: 'Select start & end date',
      saveText: 'Apply',
    );

    if (picked != null) {
      setState(() => _range = picked);
      await _fetch();
    }
  }

  // ====== API ======
  Uri _buildUri() {
    const base = 'https://mmsv2.pstw.com.my/get-marine-investigate-image-request.php';
    final params = <String, String>{
      if (_range != null) ...{
        'start': _fmt(_range!.start),
        'end': _fmt(_range!.end),
      },
      if (_selectedCategoryKey?.isNotEmpty == true)
        'category': _selectedCategoryKey!, // installation | data_collection
      if (_selectedStationID?.isNotEmpty == true)
        'station': _selectedStationID!, // optional
    };
    return Uri.parse(base).replace(queryParameters: params);
  }

  Future<void> _fetch() async {
    if (!await _hasInternet()) {
      setState(() {
        _error = 'No internet connection';
        _images = [];
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No internet connection')));
      return;
    }

    if (_range == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _images = [];
      _selectedImages.clear();
    });

    final uri = _buildUri();

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        List<String> list;
        if (decoded is List) {
          list = decoded.map<String>((e) => e.toString()).toList();
        } else if (decoded is Map && decoded['images'] is List) {
          list =
              (decoded['images'] as List).map<String>((e) => e.toString()).toList();
        } else {
          throw 'Unexpected response format';
        }
        setState(() => _images = list);
      } else {
        setState(() => _error =
        'Server error ${res.statusCode}: ${res.body.isNotEmpty ? res.body : "Unknown"}');
      }
    } catch (e) {
      setState(() => _error = 'Request failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ====== Email (SMTP) ======
  Future<List<File>> _downloadToTempFiles(List<String> urls) async {
    final dir = await getTemporaryDirectory();
    final files = <File>[];
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final name = Uri.parse(url).pathSegments.isNotEmpty
              ? Uri.parse(url).pathSegments.last
              : 'img_$i.jpg';
          final f = File('${dir.path}/$name');
          await f.writeAsBytes(res.bodyBytes);
          files.add(f);
        }
      } catch (_) {
        // Skip failed downloads
      }
    }
    return files;
  }

  List<List<File>> _chunkByTotalSize(List<File> files,
      {int maxBytes = 20 * 1024 * 1024}) {
    final chunks = <List<File>>[];
    var current = <File>[];
    var total = 0;

    for (final f in files) {
      final len = f.lengthSync();
      if (len > maxBytes) {
        if (current.isNotEmpty) {
          chunks.add(current);
          current = <File>[];
          total = 0;
        }
        chunks.add([f]);
        continue;
      }
      if (total + len > maxBytes) {
        chunks.add(current);
        current = <File>[f];
        total = len;
      } else {
        current.add(f);
        total += len;
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  Future<void> _sendEmailViaGmail({
    required String recipientEmail,
    required List<String> imageUrls,
    String subject = 'Filtered Images Attached',
    String body = 'Please find the filtered images attached.',
  }) async {
    if (!await _hasInternet()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No internet connection')));
      return;
    }

    if (!_isValidEmail(recipientEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one image')),
      );
      return;
    }

    setState(() => _sending = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Downloading images…')));

    // 1) Download
    final files = await _downloadToTempFiles(imageUrls);
    if (files.isEmpty) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2) Chunk to keep each email ≲ 20MB
    final batches = _chunkByTotalSize(files);

    // 3) SMTP
    final smtpServer = gmail(kSmtpEmail, kSmtpAppPassword);

    try {
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        final numberedSubject =
        batches.length == 1 ? subject : '$subject (${i + 1}/${batches.length})';

        final message = Message()
          ..from = Address(kSmtpEmail, 'MMS-Image Request')
          ..recipients.add(recipientEmail)
          ..subject = numberedSubject
          ..text = body
          ..attachments = batch.map((f) => FileAttachment(f)).toList();

        await send(message, smtpServer);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Email sent (${batches.length} ${batches.length == 1 ? 'message' : 'messages'})'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  // ====== Lifecycle ======
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadState();

    // Default to today's range
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );

    // Default category key from selected id
    _selectedCategoryKey = _categoryKeyMap[_selectedItemId];

    _fetch();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _range == null
        ? 'No date range selected'
        : '${_fmt(_range!.start)} → ${_fmt(_range!.end)}';

    // Enable send when: online + have selection + valid email + not sending
    final canSend = _online &&
        _selectedImages.isNotEmpty &&
        _isValidEmail(_emailCtrl.text) &&
        !_sending;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline banner
          if (!_online)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.red,
              child: const Text(
                'No Internet Connection',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Category
          DropdownButtonFormField<Item>(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            value: items.firstWhere(
                  (e) => e.id == _selectedItemId,
              orElse: () => items.first,
            ),
            items: items
                .map((item) => DropdownMenuItem<Item>(
              value: item,
              child: Text(item.categoryName),
            ))
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                selectedItem = value;
                _selectedItemId = value.id;
                _selectedCategoryKey = _categoryKeyMap[_selectedItemId];

                print(_selectedItemId);
                selectedLocalState = null;
                _isLocation = false;

              });
              await _fetch();
            },
            validator: (value) =>
            value == null ? 'Please select a category' : null,
          ),

          const SizedBox(height: 10.0),

          // State
          Row(
            children: [
              Expanded(
                child: DropdownSearch<localState>(
                  items: state1,
                  selectedItem: selectedLocalState,
                  itemAsString: (localState u) => u.stateName,
                  popupProps: const PopupProps.menu(showSearchBox: true),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Select state",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  onChanged: (localState? value) async {
                    setState(() {
                      _isLocation = true;
                      selectedLocalState = value;
                      stateID = selectedLocalState?.stateID;
                      selectedLocalLocation = null;
                      _selectedStationID = null; // clear station on state change
                    });
                    if (stateID != null) await _loadLocation(stateID);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          // Location (station)
          _isLocation
              ? DropdownSearch<localLocation>(
            items: location1,
            selectedItem: selectedLocalLocation,
            itemAsString: (localLocation u) =>
            "${u.stationID} - ${u.locationName}",
            popupProps: PopupProps.menu(
              showSearchBox: true,
              emptyBuilder: (context, searchEntry) =>
              const Center(child: Text("No records found")),
            ),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Select location",
                border: OutlineInputBorder(),
              ),
            ),
            onChanged: (localLocation? value) async {
              setState(() {
                selectedLocalLocation = value;
                _selectedStationID = value?.stationID; // optional
              });
              await _fetch();
            },
          )
              : const SizedBox.shrink(),

          const SizedBox(height: 8),

          // Toolbar + Active filters (Wrap prevents overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Pick date range',
                  ),
                  if (_range != null)
                    IconButton(
                      onPressed: _fetch,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_selectedCategoryKey != null)
                    Chip(label: Text('Category: $_selectedCategoryKey')),
                  if (_selectedStationID?.isNotEmpty == true)
                    Chip(
                      label: Text('Station: $_selectedStationID'),
                      onDeleted: () async {
                        setState(() => _selectedStationID = null);
                        await _fetch();
                      },
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Email input + send button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Recipient email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: canSend
                    ? () => _sendEmailViaGmail(
                  recipientEmail: _emailCtrl.text.trim(),
                  imageUrls: _selectedImages.toList(),
                  subject: _subjectCtrl.text.trim().isEmpty
                      ? 'Requested MMS Images'
                      : _subjectCtrl.text.trim(),
                  body:
                  'Attached are the images requested from MMS.\n'
                      'Category: ${_selectedCategoryKey ?? "-"}\n'
                      'Station: ${_selectedStationID ?? "(all)"}\n'
                      'Range: ${_fmt(_range!.start)} → ${_fmt(_range!.end)}',
                )
                    : null,
                icon: _sending
                    ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_sending
                    ? 'Sending…'
                    : _online
                    ? 'Send email'
                    : 'Offline'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          // Date range banner
          Container(
            width: double.infinity,
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.all(12),
            child: Text(
              "Date range: $rangeText",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          // Results grid with selection
          _loading
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
              : _error != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          )
              : _images.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No images found'),
            ),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (_, i) {
              final url = _images[i];
              final selected = _selectedImages.contains(url);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedImages.remove(url);
                    } else {
                      _selectedImages.add(url);
                    }
                  });
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const ColoredBox(
                            color: Colors.black12,
                            child: Center(
                                child: Icon(Icons.broken_image)),
                          ),
                          loadingBuilder:
                              (context, child, progress) {
                            if (progress == null) return child;
                            return const ColoredBox(
                              color: Colors.black12,
                              child: Center(
                                  child:
                                  CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                    // Selection overlay
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.black26
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? Colors.lightBlueAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 12,
                          child: Icon(Icons.check, size: 16),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Item {
  final int id;
  final String categoryName;
  const Item({required this.id, required this.categoryName});
  @override
  String toString() => categoryName;
}
