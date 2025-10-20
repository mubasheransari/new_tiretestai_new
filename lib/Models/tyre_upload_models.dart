// tyre_upload_models.dart
class TyreUploadRequest {
  final String userId;
  final String vehicleType; // "bike"
  final String vehicleId;
  final String? vin;        // optional
  final String frontPath;   // local file path
  final String backPath;    // local file path
  final String token;       // Bearer

  TyreUploadRequest({
    required this.userId,
    required this.vehicleType,
    required this.vehicleId,
    required this.frontPath,
    required this.backPath,
    required this.token,
    this.vin,
  });
}

class TyreUploadData {
  final String userId;
  final String vehicleType;
  final int recordId;
  final String vehicleId;
  final String? vin;
  final String frontWheelUrl;
  final String backWheelUrl;
  final String frontTyreStatus;
  final String backTyreStatus;

  TyreUploadData({
    required this.userId,
    required this.vehicleType,
    required this.recordId,
    required this.vehicleId,
    required this.frontWheelUrl,
    required this.backWheelUrl,
    required this.frontTyreStatus,
    required this.backTyreStatus,
    this.vin,
  });

  factory TyreUploadData.fromJson(Map<String, dynamic> raw) => TyreUploadData(
        userId: (raw['User ID'] ?? '').toString(),
        vehicleType: (raw['Vehicle Type'] ?? '').toString(),
        recordId: (raw['Record ID'] is int)
            ? raw['Record ID'] as int
            : int.tryParse('${raw['Record ID']}') ?? 0,
        vehicleId: (raw['Vehicle ID'] ?? '').toString(),
        vin: raw['vin']?.toString(),
        frontWheelUrl: (raw['Front Wheel'] ?? '').toString(),
        backWheelUrl: (raw['Back Wheel'] ?? '').toString(),
        frontTyreStatus: (raw['Front Tyre status'] ?? '').toString(),
        backTyreStatus: (raw['Back Tyre status'] ?? '').toString(),
      );
}

class TyreUploadResponse {
  final TyreUploadData data;
  final String? message;

  TyreUploadResponse({required this.data, this.message});

  factory TyreUploadResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = (json['data'] as Map).cast<String, dynamic>();
    return TyreUploadResponse(
      data: TyreUploadData.fromJson(dataMap),
      message: json['message']?.toString(),
    );
  }
}
