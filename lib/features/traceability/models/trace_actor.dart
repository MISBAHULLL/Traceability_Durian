enum TraceActorRole {
  farmer,
  collector,
  distributor,
  umkm,
  consumer,
  admin,
  system,
}

extension TraceActorRoleX on TraceActorRole {
  String get label {
    switch (this) {
      case TraceActorRole.farmer:
        return 'Petani';
      case TraceActorRole.collector:
        return 'Pengepul';
      case TraceActorRole.distributor:
        return 'Distributor';
      case TraceActorRole.umkm:
        return 'UMKM';
      case TraceActorRole.consumer:
        return 'Konsumen';
      case TraceActorRole.admin:
        return 'Admin';
      case TraceActorRole.system:
        return 'Sistem';
    }
  }
}

TraceActorRole traceActorRoleFromJson(Object? value) {
  return TraceActorRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => TraceActorRole.system,
  );
}
