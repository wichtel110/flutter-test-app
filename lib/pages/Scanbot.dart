import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test_app/pages_repository.dart';
import 'package:flutter_test_app/ui/barcode_preview.dart';
import 'package:flutter_test_app/ui/barcode_preview_multi_image.dart';
import 'package:flutter_test_app/ui/classical_components/barcode_custom_ui.dart';
import 'package:flutter_test_app/ui/classical_components/document_custom_ui.dart';
import 'package:flutter_test_app/ui/generic_document_preview.dart';
import 'package:flutter_test_app/ui/menu_items.dart';
import 'package:flutter_test_app/ui/preview_document_widget.dart';
import 'package:flutter_test_app/ui/progress_dialog.dart';
import 'package:flutter_test_app/ui/utils.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanbot_image_picker/models/image_picker_response.dart';
import 'package:scanbot_image_picker/scanbot_image_picker_flutter.dart';
import 'package:scanbot_sdk/generic_document_recognizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanbot_sdk/barcode_scanning_data.dart';
import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/ehic_scanning_data.dart';
import 'package:scanbot_sdk/json/common_data.dart';
import 'package:scanbot_sdk/json/common_data.dart' as common;
import 'package:scanbot_sdk/license_plate_scan_data.dart';
import 'package:scanbot_sdk/mrz_scanning_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk_models.dart' hide Status;
import 'package:scanbot_sdk/scanbot_sdk_ui.dart';

const SCANBOT_SDK_LICENSE_KEY = '';
bool shouldInitWithEncryption = false;

// TODO add the Scanbot SDK license key here.
// Please note: The Scanbot SDK will run without a license key for one minute per session!
// After the trial period is over all Scanbot SDK functions as well as the UI components will stop working
// or may be terminated. You can get an unrestricted "no-strings-attached" 30 day trial license key for free.
// Please submit the trial license form (https://scanbot.io/en/sdk/demo/trial) on our website by using
// the app identifier "io.scanbot.example.flutter" of this example app or of your app.

Future<void> _initScanbotSdk() async {
  // Consider adjusting this optional storageBaseDirectory - see the comments below.
  final customStorageBaseDirectory = await getDemoStorageBaseDirectory();

  final encryptionParams = _getEncryptionParams();

  var config = ScanbotSdkConfig(
      loggingEnabled: true,
      // Consider switching logging OFF in production builds for security and performance reasons.
      licenseKey: SCANBOT_SDK_LICENSE_KEY,
      imageFormat: ImageFormat.JPG,
      imageQuality: 80,
      storageBaseDirectory: customStorageBaseDirectory,
      documentDetectorMode: DocumentDetectorMode.ML_BASED,
      encryptionParameters: encryptionParams);
  try {
    await ScanbotSdk.initScanbotSdk(config);
    await PageRepository().loadPages();
  } catch (e) {
    Logger.root.severe(e);
  }
}

EncryptionParameters? _getEncryptionParams() {
  EncryptionParameters? encryptionParams;
  if (shouldInitWithEncryption) {
    encryptionParams = EncryptionParameters(
      password: 'SomeSecretPa\$\$w0rdForFileEncryption',
      mode: FileEncryptionMode.AES256,
    );
  }
  return encryptionParams;
}

Future<String> getDemoStorageBaseDirectory() async {
  // !! Please note !!
  // It is strongly recommended to use the default (secure) storage location of the Scanbot SDK.
  // However, for demo purposes we overwrite the "storageBaseDirectory" of the Scanbot SDK by a custom storage directory.
  //
  // On Android we use the "ExternalStorageDirectory" which is a public(!) folder.
  // All image files and export files (PDF, TIFF, etc) created by the Scanbot SDK in this demo app will be stored
  // in this public storage directory and will be accessible for every(!) app having external storage permissions!
  // Again, this is only for demo purposes, which allows us to easily fetch and check the generated files
  // via Android "adb" CLI tools, Android File Transfer app, Android Studio, etc.
  //
  // On iOS we use the "ApplicationDocumentsDirectory" which is accessible via iTunes file sharing.
  //
  // For more details about the storage system of the Scanbot SDK Flutter Plugin please see our docs:
  // - https://scanbotsdk.github.io/documentation/flutter/
  //
  // For more details about the file system on Android and iOS we also recommend to check out:
  // - https://developer.android.com/guide/topics/data/data-storage
  // - https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

  Directory storageDirectory;
  if (Platform.isAndroid) {
    storageDirectory = (await getExternalStorageDirectory())!;
  } else if (Platform.isIOS) {
    storageDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw ('Unsupported platform');
  }

  return '${storageDirectory.path}/my-custom-storage';
}

class ScanBot extends StatefulWidget {
  @override
  _ScanBotState createState() {
    _initScanbotSdk();
    return _ScanBotState();
  }
}

class _ScanBotState extends State<ScanBot> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScanbotPageWidget(),
    );
  }
}

class ScanbotPageWidget extends StatefulWidget {
  @override
  _ScanbotPageWidgetState createState() => _ScanbotPageWidgetState();
}

class _ScanbotPageWidgetState extends State<ScanbotPageWidget> {
  final PageRepository _pageRepository = PageRepository();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ScanbotRedColor,
        title: const Text(
          'Scanbot SDK Example Flutter',
        ),
      ),
      body: ListView(
        children: <Widget>[
          TitleItemWidget('Document Scanner'),
          MenuItemWidget(
            'Scan Documents',
            onTap: () {
              _startDocumentScanning();
            },
          ),
          MenuItemWidget(
            'Scan Documents (Custom UI)',
            onTap: () {
              _startDocumentsCustomUIScanner();
            },
          ),
          MenuItemWidget(
            'Generic Document Scanner',
            onTap: () {
              _startGenericDocumentScanner();
            },
          ),
          MenuItemWidget(
            'Import Image',
            onTap: () {
              _importImage();
            },
          ),
          MenuItemWidget(
            'View Image Results',
            endIcon: Icons.keyboard_arrow_right,
            onTap: () {
              _gotoImagesView();
            },
          ),
          TitleItemWidget('Data Detectors'),
          MenuItemWidget(
            'Scan Barcode (all formats: 1D + 2D)',
            onTap: () {
              _startBarcodeScanner();
            },
          ),
          MenuItemWidget(
            'Scan QR code (QR format only)',
            onTap: () {
              _startQRScanner();
            },
          ),
          MenuItemWidget(
            'Scan Multiple Barcodes (batch mode)',
            onTap: () {
              _startBatchBarcodeScanner();
            },
          ),
          MenuItemWidget(
            'Detect Barcodes from Still Image',
            onTap: () {
              _detectBarcodeOnImage();
            },
          ),
          MenuItemWidget(
            'Scan Barcode (Custom UI)',
            onTap: () {
              _startBarcodeCustomUIScanner();
            },
          ),
          MenuItemWidget(
            'Detect Barcodes from Multiple Still Images',
            onTap: () {
              _detectBarcodesOnImages();
            },
          ),
          MenuItemWidget(
            'Scan MRZ (Machine Readable Zone)',
            onTap: () {
              _startMRZScanner();
            },
          ),
          MenuItemWidget(
            'Scan EHIC (European Health Insurance Card)',
            onTap: () {
              _startEhicScanner();
            },
          ),
          MenuItemWidget(
            'Scan License Plate',
            onTap: () {
              startLicensePlateScanner();
            },
          ),
          TitleItemWidget('Test other SDK API methods'),
          MenuItemWidget(
            'getLicenseStatus()',
            startIcon: Icons.phonelink_lock,
            onTap: () {
              _getLicenseStatus();
            },
          ),
          MenuItemWidget(
            'getOcrConfigs()',
            startIcon: Icons.settings,
            onTap: () {
              _getOcrConfigs();
            },
          ),
          MenuItemWidget(
            '3rd-party Libs & Licenses',
            startIcon: Icons.developer_mode,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Scanbot SDK Flutter Example',
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _getOcrConfigs() async {
    try {
      final result = await ScanbotSdk.getOcrConfigs();
      await showAlertDialog(context, jsonEncode(result), title: 'OCR Configs');
    } catch (e) {
      Logger.root.severe(e);
      await showAlertDialog(context, 'Error getting OCR configs');
    }
  }

  Future<void> _getLicenseStatus() async {
    try {
      final result = await ScanbotSdk.getLicenseStatus();
      await showAlertDialog(context, jsonEncode(result),
          title: 'License Status');
    } catch (e) {
      Logger.root.severe(e);
      await showAlertDialog(context, 'Error getting license status');
    }
  }

  Future<void> _importImage() async {
    try {
      final response = await ScanbotImagePickerFlutter.pickImageAsync();
      var uriPath = response.uri ?? "";
      if (uriPath.isNotEmpty) {
        await _createPage(Uri.file(uriPath));
        await _gotoImagesView();
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _createPage(Uri uri) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Processing');
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      await _pageRepository.addPage(page);
    } catch (e) {
      Logger.root.severe(e);
    } finally {
      await dialog.hide();
    }
  }

  Future<void> _startDocumentScanning() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: ScanbotRedColor,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        orientationLockMode: OrientationLockMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: 'Cancel',
        pageCounterButtonTitle: '%d Page(s)',
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);
        await _gotoImagesView();
      }
    }
  }

  Future<void> _startBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        topBarBackgroundColor: ScanbotRedColor,
        barcodeFormats: PredefinedBarcodes.allBarcodeTypes(),
        cameraOverlayColor: Colors.amber,
        finderAspectRatio: const FinderAspectRatio(width: 4, height: 2),
        finderTextHint:
            'Please align any supported barcode in the frame to scan it.',
        /*  additionalParameters: BarcodeAdditionalParameters(
          enableGS1Decoding: false,
          minimumTextLength: 10,
          maximumTextLength: 11,
          minimum1DBarcodesQuietZone: 10,
        )*/
        //cameraZoomFactor: 0.5,
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      await _showBarcodeScanningResult(result);
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _startBarcodeCustomUIScanner() async {
    var result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BarcodeScannerWidget()),
    );
    if (result is BarcodeScanningResult) {
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => BarcodesResultPreviewWidget(result)),
      );
    }
  }

  Future<void> _startDocumentsCustomUIScanner() async {
    var result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DocumentScannerWidget()),
    );
    if (result is List<common.Page>) {
      _pageRepository.addPages(result);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DocumentPreview()),
      );
    }
  }

  Future<void> _startGenericDocumentScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    GenericDocumentRecognizerResult? result;
    try {
      var config = GenericDocumentRecognizerConfiguration(
        acceptedDocumentTypes: [
          RootDocumentType.DeDriverLicenseFront,
          RootDocumentType.DeDriverLicenseBack,
          RootDocumentType.DePassport,
          RootDocumentType.DeIdCardBack,
          RootDocumentType.DeIdCardFront,
        ],
      );
      result = await ScanbotSdkUi.startGenericDocumentRecognizer(config);
      _showGenericDocumentRecognizerResult(result);
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _startBatchBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      var config = BatchBarcodeScannerConfiguration(
        barcodeFormatter: (item) async {
          final random = Random();
          final randomNumber = random.nextInt(4) + 2;
          await Future.delayed(Duration(seconds: randomNumber));
          return BarcodeFormattedData(
              title: item.barcodeFormat.toString(),
              subtitle: (item.text ?? '') + 'custom string');
        },
        cancelButtonTitle: 'Cancel',
        enableCameraButtonTitle: 'camera enable',
        enableCameraExplanationText: 'explanation text',
        finderTextHint:
            'Please align any supported barcode in the frame to scan it.',
        // clearButtonTitle: "CCCClear",
        // submitButtonTitle: "Submitt",
        barcodesCountText: '%d codes',
        fetchingStateText: 'might be not needed',
        noBarcodesTitle: 'nothing to see here',
        finderAspectRatio: const FinderAspectRatio(width: 3, height: 2),
        finderLineWidth: 7,
        successBeepEnabled: true,
        // flashEnabled: true,
        orientationLockMode: OrientationLockMode.PORTRAIT,
        barcodeFormats: PredefinedBarcodes.allBarcodeTypes(),
        cancelButtonHidden: false,
        //cameraZoomFactor: 0.5
        /*additionalParameters: BarcodeAdditionalParameters(
          enableGS1Decoding: false,
          minimumTextLength: 10,
          maximumTextLength: 11,
          minimum1DBarcodesQuietZone: 10,
        )*/
      );

      final result = await ScanbotSdkUi.startBatchBarcodeScanner(config);
      if (result.operationResult == OperationResult.SUCCESS) {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => BarcodesResultPreviewWidget(result)),
        );
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _detectBarcodeOnImage() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      var response = await ScanbotImagePickerFlutter.pickImageAsync();
      var uriPath = response.uri ?? "";
      if (uriPath.isEmpty) {
        ValidateUriError(response);
        return;
      }

      ///before processing image sdk need storage read permission
      final permissions =
          await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var result = await ScanbotSdk.detectBarcodesOnImage(
            Uri.file(uriPath), PredefinedBarcodes.allBarcodeTypes());
        if (result.operationResult == OperationResult.SUCCESS) {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => BarcodesResultPreviewWidget(result)),
          );
        }
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  /// Detect barcodes from multiple still images
  Future<void> _detectBarcodesOnImages() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      List<Uri> uris = List.empty(growable: true);
      var response = await ScanbotImagePickerFlutter.pickImagesAsync();
      if (response.uris?.isNotEmpty == true) {
        uris = response.PathsToUris(response.uris);
      }

      if (response.message?.isNotEmpty == true) {
        ValidateUriError(response);
      }

      ///before processing image sdk need storage read permission
      final permissions =
          await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var result = await ScanbotSdk.detectBarcodesOnImages(
            uris, PredefinedBarcodes.allBarcodeTypes());
        if (result.operationResult == OperationResult.SUCCESS) {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MultiImageBarcodesResultPreviewWidget(
                  result.barcodeResults)));
        }
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> startLicensePlateScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    LicensePlateScanResult requestResult;
    try {
      var config = LicensePlateScannerConfiguration(
          topBarBackgroundColor: Colors.pink,
          topBarButtonsColor: Colors.white70,
          confirmationDialogAccentColor: Colors.green);
      requestResult = await ScanbotSdkUi.startLicensePlateScanner(config);
      if (requestResult.operationResult == OperationResult.SUCCESS) {
        showResultTextDialog(requestResult.rawText);
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> estimateBlurriness() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      var response = await ScanbotImagePickerFlutter.pickImageAsync();
      var uriPath = response.uri ?? "";
      if (uriPath.isEmpty) {
        ValidateUriError(response);
        return;
      }

      ///before processing an image the SDK need storage read permission
      var permissions = await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var page = await ScanbotSdk.createPage(Uri.file(uriPath), true);
        var result = await ScanbotSdk.estimateBlurOnPage(page);
        // set up the button
        showResultTextDialog('Blur value is :${result.toStringAsFixed(2)} ');
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  void showResultTextDialog(result) {
    Widget okButton = TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('OK'),
    );
    // set up the AlertDialog
    var alert = AlertDialog(
      title: const Text('Result'),
      content: Text(result),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _startQRScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      final config = BarcodeScannerConfiguration(
        barcodeFormats: [BarcodeFormat.QR_CODE],
        finderTextHint: 'Please align a QR code in the frame to scan it.',
        /*  additionalParameters: BarcodeAdditionalParameters(
          enableGS1Decoding: false,
          minimumTextLength: 10,
          maximumTextLength: 11,
          minimum1DBarcodesQuietZone: 10,
        )*/
        // ...
      );
      final result = await ScanbotSdkUi.startBarcodeScanner(config);
      await _showBarcodeScanningResult(result);
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _showBarcodeScanningResult(
      final BarcodeScanningResult result) async {
    if (result.operationResult == OperationResult.SUCCESS) {
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => BarcodesResultPreviewWidget(result)),
      );
    }
  }

  Future<void> _showGenericDocumentRecognizerResult(
      final GenericDocumentRecognizerResult result) async {
    if (result.status == Status.OK) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GenericDocumentResultPreview(result),
        ),
      );
    }
  }

  Future<void> _startEhicScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    HealthInsuranceCardRecognitionResult? result;
    try {
      final config = HealthInsuranceScannerConfiguration(
        topBarBackgroundColor: ScanbotRedColor,
        topBarButtonsColor: Colors.white70,
        // ...
      );
      result = await ScanbotSdkUi.startEhicScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        var concatenate = StringBuffer();
        result.fields
            .map((field) =>
                "${field.type.toString().replaceAll("HealthInsuranceCardFieldType.", "")}:${field.value}\n")
            .forEach((s) {
          concatenate.write(s);
        });
        await showAlertDialog(context, concatenate.toString());
      }
    }
  }

  Future<void> _startMRZScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    MrzScanningResult? result;
    try {
      final config = MrzScannerConfiguration(
        topBarBackgroundColor: ScanbotRedColor,
      );
      if (Platform.isIOS) {
        config.finderAspectRatio = const FinderAspectRatio(width: 7, height: 1);
      }
      result = await ScanbotSdkUi.startMrzScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }

    if (result != null && isOperationSuccessful(result)) {
      final concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.name.toString().replaceAll("MRZFieldName.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      await showAlertDialog(context, concatenate.toString());
    }
  }

  Future<dynamic> _gotoImagesView() async {
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentPreview()),
    );
  }

  /// Check for error message and display accordingly.
  void ValidateUriError(ImagePickerResponse response) {
    String message = response.message ?? "";
    showAlertDialog(context, message);
  }
}
