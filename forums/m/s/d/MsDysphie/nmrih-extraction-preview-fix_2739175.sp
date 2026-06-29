
#include <sdktools>
#pragma newdecls required
#pragma semicolon 1

#define SF_CAMERA_PLAYER_POSITION 1
#define SF_CAMERA_PLAYER_TARGET 2
#define SF_CAMERA_BADFLAGS (SF_CAMERA_PLAYER_POSITION|SF_CAMERA_PLAYER_TARGET)

public Plugin myinfo = {
    name        = "[NMRiH] Extraction Preview Fix",
    author      = "Dysphie",
    description = "Fixes extraction cameras displaying at the wrong origin",
    version     = "1.0.0",
    url         = ""
};

bool lateloaded;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateloaded = late;
}

public void OnPluginStart()
{
	if (lateloaded)
	{
		int e = -1;
		while ((e = FindEntityByClassname(e, "nmrih_extract_preview")) != -1)
			PatchExtractionPreview(e);
	}
}

void PatchExtractionPreview(int camera)
{
	int spawnflags = GetEntProp(camera, Prop_Data, "m_spawnflags");
	if (spawnflags & SF_CAMERA_BADFLAGS)
	{
		spawnflags &= ~SF_CAMERA_BADFLAGS;
		SetEntProp(camera, Prop_Data, "m_spawnflags", spawnflags);
	}
}

public void OnEntitySpawned(int entity, const char[] classname)
{
	if (!IsValidEntity(entity))
		return;

	if (IsEntityExtractionPreview(entity))
		PatchExtractionPreview(entity);
}

bool IsEntityExtractionPreview(int entity)
{
	return HasEntProp(entity, Prop_Data, "m_nOldTakeDamageVec");
}