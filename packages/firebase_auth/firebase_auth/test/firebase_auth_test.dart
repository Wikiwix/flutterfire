// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import './mock.dart';

import 'package:mockito/mockito.dart';

void main() {
  setupFirebaseAuthMocks();

  FirebaseAuth? auth;

  const String kMockActionCode = '12345';
  const String kMockEmail = 'test@example.com';
  const String kMockPassword = 'passw0rd';
  const String kMockIdToken = '12345';
  const String kMockAccessToken = '67890';
  const String kMockGithubToken = 'github';
  const String kMockCustomToken = '12345';
  const String kMockPhoneNumber = '5555555555';
  const String kMockVerificationId = '12345';
  const String kMockSmsCode = '123456';
  const String kMockLanguage = 'en';
  const String kMockOobCode = 'oobcode';
  const String kMockURL = 'http://www.example.com';

  final TestAuthProvider testAuthProvider = TestAuthProvider();
  final int kMockCreationTimestamp =
      DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  final int kMockLastSignInTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

  Map<String, dynamic> kMockUser = <String, dynamic>{
    'isAnonymous': true,
    'emailVerified': false,
    'displayName': 'displayName',
    'metadata': <String, int>{
      'creationTime': kMockCreationTimestamp,
      'lastSignInTime': kMockLastSignInTimestamp,
    },
    'providerData': <Map<String, String>>[
      <String, String>{
        'providerId': 'firebase',
        'uid': '12345',
        'displayName': 'Flutter Test User',
        'photoURL': 'http://www.example.com/',
        'email': 'test@example.com',
      },
    ],
  };

  MockUserPlatform? mockUserPlatform;
  MockUserCredentialPlatform? mockUserCredPlatform;
  MockConfirmationResultPlatform? mockConfirmationResultPlatform;
  MockRecaptchaVerifier? mockVerifier;
  AdditionalUserInfo? mockAdditionalUserInfo;
  EmailAuthCredential? mockCredential;

  MockFirebaseAuth mockAuthPlatform = MockFirebaseAuth();

  group('$FirebaseAuth', () {
    Map<String, dynamic> user;
    // used to generate a unique application name for each test
    var testCount = 0;

    setUp(() async {
      FirebaseAuthPlatform.instance = mockAuthPlatform = MockFirebaseAuth();

      // Each test uses a unique FirebaseApp instance to avoid sharing state
      final app = await Firebase.initializeApp(
        name: '$testCount',
        options: const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        ),
      );

      auth = FirebaseAuth.instanceFor(app: app);
      user = kMockUser;

      mockUserPlatform = MockUserPlatform(mockAuthPlatform, user);
      mockConfirmationResultPlatform = MockConfirmationResultPlatform();
      mockAdditionalUserInfo = AdditionalUserInfo(
        isNewUser: false,
        username: 'flutterUser',
        providerId: 'testProvider',
        profile: <String, dynamic>{'foo': 'bar'},
      );
      mockCredential = EmailAuthProvider.credential(
        email: 'test',
        password: 'test',
      ) as EmailAuthCredential;
      mockUserCredPlatform = MockUserCredentialPlatform(
        FirebaseAuthPlatform.instance,
        mockAdditionalUserInfo!,
        mockCredential!,
        mockUserPlatform!,
      );
      mockVerifier = MockRecaptchaVerifier();

      when(mockAuthPlatform.signInAnonymously())
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithCredential(any)).thenAnswer(
          (_) => Future<UserCredentialPlatform>.value(mockUserCredPlatform));

      when(mockAuthPlatform.currentUser).thenReturn(mockUserPlatform);

      when(mockAuthPlatform.instanceFor(
        app: anyNamed('app'),
        pluginConstants: anyNamed('pluginConstants'),
      )).thenAnswer((_) => mockUserPlatform);

      when(mockAuthPlatform.delegateFor(
        app: anyNamed('app'),
      )).thenAnswer((_) => mockAuthPlatform);

      when(mockAuthPlatform.setInitialValues(
        currentUser: anyNamed('currentUser'),
        languageCode: anyNamed('languageCode'),
      )).thenAnswer((_) => mockAuthPlatform);

      when(mockAuthPlatform.createUserWithEmailAndPassword(any, any))
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.getRedirectResult())
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithCustomToken(any))
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithEmailAndPassword(any, any))
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithEmailLink(any, any))
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithPhoneNumber(any, any))
          .thenAnswer((_) async => mockConfirmationResultPlatform!);

      when(mockVerifier!.delegate).thenReturn(mockVerifier!.mockDelegate);

      when(mockAuthPlatform.signInWithPopup(any))
          .thenAnswer((_) async => mockUserCredPlatform!);

      when(mockAuthPlatform.signInWithRedirect(any))
          .thenAnswer((_) async => mockUserCredPlatform);

      when(mockAuthPlatform.authStateChanges()).thenAnswer((_) =>
          Stream<UserPlatform>.fromIterable(<UserPlatform>[mockUserPlatform!]));

      when(mockAuthPlatform.idTokenChanges()).thenAnswer((_) =>
          Stream<UserPlatform>.fromIterable(<UserPlatform>[mockUserPlatform!]));

      when(mockAuthPlatform.userChanges()).thenAnswer((_) =>
          Stream<UserPlatform>.fromIterable(<UserPlatform>[mockUserPlatform!]));

      MethodChannelFirebaseAuth.channel.setMockMethodCallHandler((call) async {
        return <String, dynamic>{'user': user};
      });
    });

    // incremented after tests completed, in case a test may want to use this
    // value for an assertion (toString)
    tearDown(() => testCount++);

    setUp(() async {
      user = kMockUser;
      await auth!.signInAnonymously();
    });

    group('currentUser', () {
      test('get currentUser', () {
        User? user = auth!.currentUser;
        verify(mockAuthPlatform.currentUser);
        expect(user, isA<User>());
      });
    });

    group('languageCode', () {
      test('.languageCode should call delegate method', () {
        auth!.languageCode;
        verify(mockAuthPlatform.languageCode);
      });

      test('setLanguageCode() should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.setLanguageCode(any)).thenAnswer((i) async {});

        await auth!.setLanguageCode(kMockLanguage);
        verify(mockAuthPlatform.setLanguageCode(kMockLanguage));
      });
    });

    group('checkActionCode()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.checkActionCode(any))
            .thenAnswer((i) async => ActionCodeInfo(data: {}, operation: 0));

        await auth!.checkActionCode(kMockActionCode);
        verify(mockAuthPlatform.checkActionCode(kMockActionCode));
      });
    });

    group('confirmPasswordReset()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.confirmPasswordReset(any, any))
            .thenAnswer((i) async {});

        await auth!.confirmPasswordReset(
          code: kMockActionCode,
          newPassword: kMockPassword,
        );
        verify(mockAuthPlatform.confirmPasswordReset(
            kMockActionCode, kMockPassword));
      });
    });

    group('createUserWithEmailAndPassword()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.createUserWithEmailAndPassword(any, any))
            .thenAnswer((i) async => EmptyUserCredentialPlatform());

        await auth!.createUserWithEmailAndPassword(
          email: kMockEmail,
          password: kMockPassword,
        );

        verify(mockAuthPlatform.createUserWithEmailAndPassword(
          kMockEmail,
          kMockPassword,
        ));
      });
    });

    group('fetchSignInMethodsForEmail()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.fetchSignInMethodsForEmail(any))
            .thenAnswer((i) async => []);

        await auth!.fetchSignInMethodsForEmail(kMockEmail);
        verify(mockAuthPlatform.fetchSignInMethodsForEmail(kMockEmail));
      });
    });

    group('getRedirectResult()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.getRedirectResult())
            .thenAnswer((i) async => EmptyUserCredentialPlatform());

        await auth!.getRedirectResult();
        verify(mockAuthPlatform.getRedirectResult());
      });
    });

    group('isSignInWithEmailLink()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.isSignInWithEmailLink(any))
            .thenAnswer((i) => false);

        auth!.isSignInWithEmailLink(kMockURL);
        verify(mockAuthPlatform.isSignInWithEmailLink(kMockURL));
      });
    });

    group('authStateChanges()', () {
      test('should stream changes', () async {
        final StreamQueue<User?> changes =
            StreamQueue<User?>(auth!.authStateChanges());
        expect(await changes.next, isA<User>());
      });
    });

    group('idTokenChanges()', () {
      test('should stream changes', () async {
        final StreamQueue<User?> changes =
            StreamQueue<User?>(auth!.idTokenChanges());
        expect(await changes.next, isA<User>());
      });
    });

    group('userChanges()', () {
      test('should stream changes', () async {
        final StreamQueue<User?> changes =
            StreamQueue<User?>(auth!.userChanges());
        expect(await changes.next, isA<User>());
      });
    });

    group('sendPasswordResetEmail()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.sendPasswordResetEmail(any))
            .thenAnswer((i) async {});

        await auth!.sendPasswordResetEmail(email: kMockEmail);
        verify(mockAuthPlatform.sendPasswordResetEmail(kMockEmail));
      });
    });

    group('sendPasswordResetEmail()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.sendPasswordResetEmail(any))
            .thenAnswer((i) async {});

        await auth!.sendPasswordResetEmail(email: kMockEmail);
        verify(mockAuthPlatform.sendPasswordResetEmail(kMockEmail));
      });
    });

    group('sendSignInLinkToEmail()', () {
      test('should throw if actionCodeSettings.handleCodeInApp is not true',
          () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.sendSignInLinkToEmail(any, any))
            .thenAnswer((i) async {});

        final ActionCodeSettings kMockActionCodeSettingsNull =
            ActionCodeSettings(url: kMockURL);
        final ActionCodeSettings kMockActionCodeSettingsFalse =
            ActionCodeSettings(url: kMockURL, handleCodeInApp: false);

        // when handleCodeInApp is null
        expect(
          () => auth!.sendSignInLinkToEmail(
              email: kMockEmail,
              actionCodeSettings: kMockActionCodeSettingsNull),
          throwsArgumentError,
        );
        // when handleCodeInApp is false
        expect(
          () => auth!.sendSignInLinkToEmail(
              email: kMockEmail,
              actionCodeSettings: kMockActionCodeSettingsFalse),
          throwsArgumentError,
        );
      });

      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.sendSignInLinkToEmail(any, any))
            .thenAnswer((i) async {});

        final ActionCodeSettings kMockActionCodeSettingsValid =
            ActionCodeSettings(url: kMockURL, handleCodeInApp: true);

        await auth!.sendSignInLinkToEmail(
          email: kMockEmail,
          actionCodeSettings: kMockActionCodeSettingsValid,
        );

        verify(mockAuthPlatform.sendSignInLinkToEmail(
          kMockEmail,
          kMockActionCodeSettingsValid,
        ));
      });
    });

    group('setSettings()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.setSettings(
          appVerificationDisabledForTesting: any,
        )).thenAnswer((i) async {});

        await auth!.setSettings(appVerificationDisabledForTesting: true);

        verify(
          mockAuthPlatform.setSettings(appVerificationDisabledForTesting: true),
        );
      });
    });

    group('setPersistence()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.setPersistence(any)).thenAnswer((i) async {});

        await auth!.setPersistence(Persistence.LOCAL);
        verify(mockAuthPlatform.setPersistence(Persistence.LOCAL));
      });
    });

    group('signInAnonymously()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.signInAnonymously())
            .thenAnswer((i) async => EmptyUserCredentialPlatform());

        await auth!.signInAnonymously();
        verify(mockAuthPlatform.signInAnonymously());
      });
    });

    group('signInWithCredential()', () {
      test('GithubAuthProvider signInWithCredential', () async {
        final AuthCredential credential =
            GithubAuthProvider.credential(kMockGithubToken);
        await auth!.signInWithCredential(credential);
        final GithubAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('github.com'));
        expect(captured.accessToken, equals(kMockGithubToken));
      });

      test('EmailAuthProvider (withLink) signInWithCredential', () async {
        final AuthCredential credential = EmailAuthProvider.credentialWithLink(
          email: 'test@example.com',
          emailLink: '<Url with domain from your Firebase project>',
        );
        await auth!.signInWithCredential(credential);
        final EmailAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('password'));
        expect(captured.email, equals('test@example.com'));
        expect(captured.emailLink,
            equals('<Url with domain from your Firebase project>'));
      });

      test('TwitterAuthProvider signInWithCredential', () async {
        final AuthCredential credential = TwitterAuthProvider.credential(
          accessToken: kMockIdToken,
          secret: kMockAccessToken,
        );
        await auth!.signInWithCredential(credential);
        final TwitterAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('twitter.com'));
        expect(captured.accessToken, equals(kMockIdToken));
        expect(captured.secret, equals(kMockAccessToken));
      });

      test('GoogleAuthProvider signInWithCredential', () async {
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: kMockIdToken,
          accessToken: kMockAccessToken,
        );
        await auth!.signInWithCredential(credential);
        final GoogleAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('google.com'));
        expect(captured.idToken, equals(kMockIdToken));
        expect(captured.accessToken, equals(kMockAccessToken));
      });

      test('OAuthProvider signInWithCredential for Apple', () async {
        OAuthProvider oAuthProvider = OAuthProvider('apple.com');
        final AuthCredential credential = oAuthProvider.credential(
          idToken: kMockIdToken,
          accessToken: kMockAccessToken,
        );
        await auth!.signInWithCredential(credential);
        final OAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('apple.com'));
        expect(captured.idToken, equals(kMockIdToken));
        expect(captured.accessToken, equals(kMockAccessToken));
      });

      test('PhoneAuthProvider signInWithCredential', () async {
        final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: kMockVerificationId,
          smsCode: kMockSmsCode,
        );
        await auth!.signInWithCredential(credential);
        final PhoneAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('phone'));
        expect(captured.verificationId, equals(kMockVerificationId));
        expect(captured.smsCode, equals(kMockSmsCode));
      });

      test('FacebookAuthProvider signInWithCredential', () async {
        final AuthCredential credential =
            FacebookAuthProvider.credential(kMockAccessToken);
        await auth!.signInWithCredential(credential);
        final FacebookAuthCredential captured =
            verify(mockAuthPlatform.signInWithCredential(captureAny))
                .captured
                .single;
        expect(captured.providerId, equals('facebook.com'));
        expect(captured.accessToken, equals(kMockAccessToken));
      });
    });

    group('signInWithCustomToken()', () {
      test('should call delegate method', () async {
        await auth!.signInWithCustomToken(kMockCustomToken);
        verify(mockAuthPlatform.signInWithCustomToken(kMockCustomToken));
      });
    });

    group('signInWithEmailAndPassword()', () {
      test('should call delegate method', () async {
        await auth!.signInWithEmailAndPassword(
            email: kMockEmail, password: kMockPassword);
        verify(mockAuthPlatform.signInWithEmailAndPassword(
            kMockEmail, kMockPassword));
      });
    });

    group('signInWithEmailLink()', () {
      test('should call delegate method', () async {
        await auth!.signInWithEmailLink(email: kMockEmail, emailLink: kMockURL);
        verify(mockAuthPlatform.signInWithEmailLink(kMockEmail, kMockURL));
      });
    });

    group('signInWithPhoneNumber()', () {
      test('should call delegate method', () async {
        await auth!.signInWithPhoneNumber(kMockPhoneNumber, mockVerifier);
        verify(mockAuthPlatform.signInWithPhoneNumber(kMockPhoneNumber, any));
      });
    });

    group('signInWithPopup()', () {
      test('should call delegate method', () async {
        await auth!.signInWithPopup(testAuthProvider);
        verify(mockAuthPlatform.signInWithPopup(testAuthProvider));
      });
    });

    group('signInWithRedirect()', () {
      test('should call delegate method', () async {
        await auth!.signInWithRedirect(testAuthProvider);
        verify(mockAuthPlatform.signInWithRedirect(testAuthProvider));
      });
    });

    group('signOut()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.signOut()).thenAnswer((i) async {});

        await auth!.signOut();
        verify(mockAuthPlatform.signOut());
      });
    });

    group('verifyPasswordResetCode()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.verifyPasswordResetCode(any))
            .thenAnswer((i) async => '');

        await auth!.verifyPasswordResetCode(kMockOobCode);
        verify(mockAuthPlatform.verifyPasswordResetCode(kMockOobCode));
      });
    });

    group('verifyPhoneNumber()', () {
      test('should call delegate method', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockAuthPlatform.verifyPhoneNumber(
          autoRetrievedSmsCodeForTesting:
              anyNamed('autoRetrievedSmsCodeForTesting'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
          codeSent: anyNamed('codeSent'),
          forceResendingToken: anyNamed('forceResendingToken'),
          phoneNumber: anyNamed('phoneNumber'),
          timeout: anyNamed('timeout'),
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
        )).thenAnswer((i) async {});

        final PhoneVerificationCompleted verificationCompleted =
            (PhoneAuthCredential phoneAuthCredential) {};
        final PhoneVerificationFailed verificationFailed =
            (FirebaseAuthException authException) {};
        final PhoneCodeSent codeSent =
            (String verificationId, [int? forceResendingToken]) async {};
        final PhoneCodeAutoRetrievalTimeout autoRetrievalTimeout =
            (String verificationId) {};

        await auth!.verifyPhoneNumber(
          phoneNumber: kMockPhoneNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: autoRetrievalTimeout,
        );

        verify(
          mockAuthPlatform.verifyPhoneNumber(
            phoneNumber: kMockPhoneNumber,
            verificationCompleted: verificationCompleted,
            verificationFailed: verificationFailed,
            codeSent: codeSent,
            codeAutoRetrievalTimeout: autoRetrievalTimeout,
          ),
        );
      });
    });

    test('toString()', () async {
      expect(
        auth!.toString(),
        equals('FirebaseAuth(app: $testCount)'),
      );
    });
  });
}

class MockFirebaseAuth extends Mock
    with MockPlatformInterfaceMixin
    implements TestFirebaseAuthPlatform {
  @override
  Stream<UserPlatform?> userChanges() {
    return super.noSuchMethod(
      Invocation.method(#userChanges, []),
      const Stream<UserPlatform?>.empty(),
    );
  }

  @override
  Stream<UserPlatform?> idTokenChanges() {
    return super.noSuchMethod(
      Invocation.method(#idTokenChanges, []),
      const Stream<UserPlatform?>.empty(),
    );
  }

  @override
  Stream<UserPlatform?> authStateChanges() {
    return super.noSuchMethod(
      Invocation.method(#authStateChanges, []),
      const Stream<UserPlatform?>.empty(),
    );
  }

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) {
    return super.noSuchMethod(
      Invocation.method(#delegateFor, [], {#app: app}),
      TestFirebaseAuthPlatform(),
    );
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String? email,
    String? password,
  ) {
    return super.noSuchMethod(
      Invocation.method(#createUserWithEmailAndPassword, [email, password]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<ConfirmationResultPlatform> signInWithPhoneNumber(
    String? phoneNumber,
    RecaptchaVerifierFactoryPlatform? applicationVerifier,
  ) {
    return super.noSuchMethod(
      Invocation.method(
        #signInWithPhoneNumber,
        [phoneNumber, applicationVerifier],
      ),
      neverEndingFuture<ConfirmationResultPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential? credential,
  ) {
    return super.noSuchMethod(
      Invocation.method(#signInWithCredential, [credential]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String? token) {
    return super.noSuchMethod(
      Invocation.method(#signInWithCustomToken, [token]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String? email,
    String? password,
  ) {
    return super.noSuchMethod(
      Invocation.method(#signInWithEmailAndPassword, [email, password]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider? provider) {
    return super.noSuchMethod(
      Invocation.method(#signInWithPopup, [provider]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
    String? email,
    String? emailLink,
  ) {
    return super.noSuchMethod(
      Invocation.method(#signInWithEmailLink, [email, emailLink]),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<void> signInWithRedirect(AuthProvider? provider) {
    return super.noSuchMethod(
      Invocation.method(#signInWithRedirect, [provider]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() {
    return super.noSuchMethod(
      Invocation.method(#signInAnonymously, []),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return super.noSuchMethod(
      Invocation.method(#signInAnonymously, [], {
        #currentUser: currentUser,
        #languageCode: languageCode,
      }),
      TestFirebaseAuthPlatform(),
    );
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() {
    return super.noSuchMethod(
      Invocation.method(#getRedirectResult, []),
      neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<void> setLanguageCode(String? languageCode) {
    return super.noSuchMethod(
      Invocation.method(#setLanguageCode, [languageCode]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String? code) {
    return super.noSuchMethod(
      Invocation.method(#checkActionCode, [code]),
      neverEndingFuture<ActionCodeInfo>(),
    );
  }

  @override
  Future<void> confirmPasswordReset(String? code, String? newPassword) {
    return super.noSuchMethod(
      Invocation.method(#confirmPasswordReset, [code, newPassword]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String? email) {
    return super.noSuchMethod(
      Invocation.method(#checkActionCode, [email]),
      neverEndingFuture<List<String>>(),
    );
  }

  @override
  bool isSignInWithEmailLink(String? emailLink) {
    return super.noSuchMethod(
      Invocation.method(#isSignInWithEmailLink, [emailLink]),
      false,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(
    String? email, [
    ActionCodeSettings? actionCodeSettings,
  ]) {
    return super.noSuchMethod(
      Invocation.method(#sendPasswordResetEmail, [email, actionCodeSettings]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> sendSignInLinkToEmail(
    String? email,
    ActionCodeSettings? actionCodeSettings,
  ) {
    return super.noSuchMethod(
      Invocation.method(#sendSignInLinkToEmail, [email, actionCodeSettings]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> setSettings({
    bool? appVerificationDisabledForTesting,
    String? userAccessGroup,
  }) {
    return super.noSuchMethod(
      Invocation.method(#setSettings, [
        appVerificationDisabledForTesting,
        userAccessGroup,
      ]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> setPersistence(Persistence? persistence) {
    return super.noSuchMethod(
      Invocation.method(#setPersistence, [persistence]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> signOut() {
    return super.noSuchMethod(
      Invocation.method(#signOut, [signOut]),
      neverEndingFuture<void>(),
    );
  }

  @override
  Future<String> verifyPasswordResetCode(String? code) {
    return super.noSuchMethod(
      Invocation.method(#verifyPasswordResetCode, [code]),
      neverEndingFuture<String>(),
    );
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    Object? verificationCompleted,
    Object? verificationFailed,
    Object? codeSent,
    Object? codeAutoRetrievalTimeout,
    Duration? timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    String? autoRetrievedSmsCodeForTesting,
  }) {
    return super.noSuchMethod(
      Invocation.method(#verifyPhoneNumber, [], {
        #phoneNumber: phoneNumber,
        #verificationCompleted: verificationCompleted,
        #verificationFailed: verificationFailed,
        #codeSent: codeSent,
        #codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        #timeout: timeout,
        #forceResendingToken: forceResendingToken,
        #autoRetrievedSmsCodeForTesting: autoRetrievedSmsCodeForTesting,
      }),
      neverEndingFuture<String>(),
    );
  }
}

class MockUserPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestUserPlatform {
  MockUserPlatform(FirebaseAuthPlatform auth, Map<String, dynamic> _user) {
    TestUserPlatform(auth, _user);
  }
}

class MockUserCredentialPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestUserCredentialPlatform {
  MockUserCredentialPlatform(
    FirebaseAuthPlatform auth,
    AdditionalUserInfo additionalUserInfo,
    AuthCredential credential,
    UserPlatform userPlatform,
  ) {
    TestUserCredentialPlatform(
      auth,
      additionalUserInfo,
      credential,
      userPlatform,
    );
  }
}

class MockConfirmationResultPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestConfirmationResultPlatform {
  MockConfirmationResultPlatform() {
    TestConfirmationResultPlatform();
  }
}

class TestConfirmationResultPlatform extends ConfirmationResultPlatform {
  TestConfirmationResultPlatform() : super('TEST');
}

class TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  TestFirebaseAuthPlatform() : super();

  void instanceFor({
    FirebaseApp? app,
    Map<dynamic, dynamic>? pluginConstants,
  }) {}

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) {
    return this;
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return this;
  }
}

class MockRecaptchaVerifier extends Mock
    with MockPlatformInterfaceMixin
    implements TestRecaptchaVerifier {
  MockRecaptchaVerifier() {
    TestRecaptchaVerifier();
  }

  RecaptchaVerifierFactoryPlatform get mockDelegate {
    return MockRecaptchaVerifierFactoryPlatform();
  }

  @override
  RecaptchaVerifierFactoryPlatform get delegate {
    return super.noSuchMethod(
      Invocation.getter(#delegate),
      MockRecaptchaVerifierFactoryPlatform(),
    );
  }
}

class MockRecaptchaVerifierFactoryPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestRecaptchaVerifierFactoryPlatform {
  MockRecaptchaVerifierFactoryPlatform() {
    TestRecaptchaVerifierFactoryPlatform();
  }
}

class TestRecaptchaVerifier implements RecaptchaVerifier {
  TestRecaptchaVerifier() : super();

  @override
  void clear() {}

  @override
  RecaptchaVerifierFactoryPlatform get delegate =>
      TestRecaptchaVerifierFactoryPlatform();

  @override
  Future<int> render() {
    throw UnimplementedError();
  }

  @override
  String get type => throw UnimplementedError();

  @override
  Future<String> verify() {
    throw UnimplementedError();
  }
}

class TestRecaptchaVerifierFactoryPlatform
    extends RecaptchaVerifierFactoryPlatform {}

class TestAuthProvider extends AuthProvider {
  TestAuthProvider() : super('TEST');
}

class TestUserPlatform extends UserPlatform {
  TestUserPlatform(FirebaseAuthPlatform auth, Map<String, dynamic> data)
      : super(auth, data);
}

class TestUserCredentialPlatform extends UserCredentialPlatform {
  TestUserCredentialPlatform(
    FirebaseAuthPlatform auth,
    AdditionalUserInfo additionalUserInfo,
    AuthCredential credential,
    UserPlatform userPlatform,
  ) : super(
          auth: auth,
          additionalUserInfo: additionalUserInfo,
          credential: credential,
          user: userPlatform,
        );
}

class EmptyUserCredentialPlatform extends UserCredentialPlatform {
  EmptyUserCredentialPlatform() : super(auth: FirebaseAuthPlatform.instance);
}
