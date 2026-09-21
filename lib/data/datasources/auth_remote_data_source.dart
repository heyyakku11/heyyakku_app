import '../models/auth/logout_request.dart';
import '../models/auth/refresh_token_request.dart';
import '../models/auth/send_otp_data.dart';
import '../models/auth/send_otp_request_model.dart';
import '../models/auth/token_response.dart';
import '../models/auth/verify_otp_data.dart';
import '../models/auth/verify_otp_request_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<SendOtpData> sendOtp(SendOtpRequestModel request);

  Future<VerifyOtpData> verifyOtp(VerifyOtpRequestModel request);

  Future<TokenResponse> refresh(RefreshTokenRequest request);

  Future<void> logout(LogoutRequestModel request, {String? accessToken});
}
