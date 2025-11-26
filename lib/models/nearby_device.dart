class NearbyDevice {
  final String endpointId;
  final String endpointName;
  final String displayName;
  final bool isAvailable;
  final bool isConnected;

  NearbyDevice({
    required this.endpointId,
    required this.endpointName,
    this.displayName = "",
    this.isAvailable = true,
    this.isConnected = false,
  });

  NearbyDevice copyWith({
    String? endpointName,
    String? displayName,
    bool? isAvailable,
    bool? isConnected,
  }) {
    return NearbyDevice(
      endpointId: endpointId,
      endpointName: endpointName ?? this.endpointName,
      displayName: displayName ?? this.displayName,
      isAvailable: isAvailable ?? this.isAvailable,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
