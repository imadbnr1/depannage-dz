import '../models/app_request.dart';
import '../models/request_status.dart';

abstract class RequestRepository {
  Stream<List<AppRequest>> watchRequests();
  List<AppRequest> currentRequests();
  Future<void> addRequest(AppRequest request);
  Future<void> updateRequest(String requestId, AppRequest request);
  Future<void> updateStatus(String requestId, RequestStatus status);
}
