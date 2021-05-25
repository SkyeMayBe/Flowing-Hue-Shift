bool IsInMirror(){
	return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

void MirrorCheck(){
	UNITY_BRANCH
    if (IsInMirror()) discard;
}