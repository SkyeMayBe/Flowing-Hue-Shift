bool isVR() {
    #if UNITY_SINGLE_PASS_STEREO
        return true;
    #else
        return false;
    #endif
}

bool isVRHandCamera() {
    return !isVR() && abs(UNITY_MATRIX_V[0].y) > 0.0000005;
}

bool isDesktop() {
    return !isVR() && abs(UNITY_MATRIX_V[0].y) < 0.0000005;
}

bool isVRHandCameraPreview() {
    return isVRHandCamera() && _ScreenParams.y == 720;
}

bool isVRHandCameraPicture() {
    return isVRHandCamera() && _ScreenParams.y == 1080;
}

bool isPanorama() {
    return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

bool isInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}