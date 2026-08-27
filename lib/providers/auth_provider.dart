import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // UPDATED: Added serverClientId to fix Android ApiException 10
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '611728246126-35f8j40i6t76pmdmpvo4cpiupt8g6tvm.apps.googleusercontent.com',
    clientId: kIsWeb
        ? '611728246126-35f8j40i6t76pmdmpvo4cpiupt8g6tvm.apps.googleusercontent.com'
        : null,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _googleSignInError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  String? get googleSignInError => _googleSignInError;

  Future<void> loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        String? fcmToken = await NotificationService.initialize();
        if (fcmToken != null) {
          await NotificationService.saveFCMToken(userId, fcmToken);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Load user data error: $e');
    }
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.reload();

      await userCredential.user!.sendEmailVerification();

      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
        role: 'customer',
        isRegistered: true,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'needsVerification': true,
        'message':
            'Account created! Please check your email to verify your account.',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Sign up error: $e');
      return {
        'success': false,
        'needsVerification': false,
        'message': 'Sign up failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> signInWithEmail(
      String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'needsVerification': true,
          'message':
              'Please verify your email before signing in. Check your inbox.',
        };
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      String? fcmToken = await NotificationService.initialize();
      if (fcmToken != null) {
        await NotificationService.saveFCMToken(
            userCredential.user!.uid, fcmToken);
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'needsVerification': false,
        'needsLocation': !isAdmin() && _currentUser?.latitude == null,
        'message': 'Signed in successfully!',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Sign in error: $e');
      return {
        'success': false,
        'needsVerification': false,
        'needsLocation': false,
        'message': 'Invalid email or password',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message':
            'Password reset link sent to $email. Check your inbox (and spam folder).',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Failed to send reset email. Please try again.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.'
      };
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print('Resend verification error: $e');
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;
        return user?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      print('Check verification error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _googleSignInError = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phone: '',
          address: 'Faisalabad',
          role: 'customer',
          isRegistered: true,
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
        _currentUser = newUser;
      } else {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      String? fcmToken = await NotificationService.initialize();
      if (fcmToken != null) {
        await NotificationService.saveFCMToken(
            userCredential.user!.uid, fcmToken);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _googleSignInError = e.toString();
      notifyListeners();
      print('Google sign in error: $e');
      return false;
    }
  }

  Future<bool> updateUserLocation(String userId) async {
    try {
      Position? position = await LocationService.getCurrentLocation();

      if (position != null) {
        String? address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        await _firestore.collection('users').doc(userId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'fullAddress': address,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            latitude: position.latitude,
            longitude: position.longitude,
            fullAddress: address,
            locationUpdatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('Error updating location: $e');
    }
    return false;
  }

  Future<bool> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'phone': phone,
        'address': address,
      });

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          phone: phone,
          address: address,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
    String userId,
    XFile image,
  ) async {
    try {
      final imageBytes = await image.readAsBytes();
      if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Choose a profile photo smaller than 5 MB.',
        };
      }

      final storageRef =
          FirebaseStorage.instance.ref().child('profile_photos/$userId');
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
      );
      final imageUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImageUrl: imageUrl);
        notifyListeners();
      }
      return {
        'success': true,
        'message': 'Profile photo updated successfully!',
      };
    } on FirebaseException catch (e) {
      print('Firebase Storage error uploading profile image: ${e.code}');
      return {
        'success': false,
        'message': _profileImageUploadError(e.code),
      };
    } catch (e) {
      print('Error uploading profile image: $e');
      return {
        'success': false,
        'message': 'Unable to upload profile photo. Check your connection.',
      };
    }
  }

  String _profileImageUploadError(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'Sign in again before uploading your profile photo.';
      case 'unauthorized':
        return 'Photo upload was blocked by Firebase Storage rules.';
      case 'bucket-not-found':
      case 'project-not-found':
        return 'Firebase Storage is not enabled for this app yet.';
      case 'quota-exceeded':
        return 'Firebase Storage quota has been exceeded.';
      case 'retry-limit-exceeded':
        return 'Photo upload timed out. Check your connection and try again.';
      default:
        return 'Unable to upload profile photo. Firebase error: $code.';
    }
  }

  Future<void> updateNotificationPreferences(
    String userId,
    NotificationPreferences prefs,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationPrefs': prefs.toMap(),
      });

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(notificationPrefs: prefs);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating notification preferences: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  bool isAdmin() {
    return _currentUser?.role == 'admin';
  }
}
