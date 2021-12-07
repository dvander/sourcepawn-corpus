#include <sdktools>
#include <sourcemod>

#define PLUGIN_NAME "CONGA!"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Do the Conga! Even without the taunt item or any other Person with it."
#define PLUGIN_URL "NULL"

#define CONGA_SNDCHAN 25
#define CONGA_SND "music/conga_sketch_167bpm_01-04.wav"

new AnimationModels[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

public OnPluginStart(){
	
	RegConsoleCmd("sm_conga", Conga, "Runs the assigned test function");
	RegConsoleCmd("sm_congastop", CongaStop, "");
	CreateConVar("conga_version", PLUGIN_VERSION, "CONGA! Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}

public OnMapStart() {
	PrecacheSound("music/conga_sketch_167bpm_01-04.wav", true);
}

public Action:Conga(client, args) {
	CongaStop(client, args);
	SetEntityRenderMode(client, RENDER_NONE);
	SetMiscsRender(client, RENDER_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	new String:Anim[] = "taunt_conga";
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model)) {
		new Float:pos[3], Float:angles[3];
		decl String:ClientModel[256], String:Skin[2];
		
		GetClientModel(client, ClientModel, sizeof(ClientModel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, Skin, sizeof(Skin));
		
		DispatchKeyValue(Model, "skin", Skin);
		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", Anim);	
		DispatchKeyValueVector(Model, "angles", angles);
		
		DispatchSpawn(Model);
		
		SetVariantString(Anim);
		AcceptEntityInput(Model, "SetAnimation");
		
		SetVariantString("");
		AcceptEntityInput(Model, "FireUser1");
		AnimationModels[client] = EntIndexToEntRef(Model);
	}
	if(IsSoundPrecached(CONGA_SND)) {
		EmitSoundToClient(client, CONGA_SND, SOUND_FROM_PLAYER, CONGA_SNDCHAN);
	}
	return Plugin_Handled;
}
public Action:CongaStop(client, args) {
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetMiscsRender(client, RENDER_NORMAL);
	SetEntityMoveType(client, MOVETYPE_WALK);
	if(AnimationModels[client] != INVALID_ENT_REFERENCE) {
		AcceptEntityInput(AnimationModels[client], "kill");
		AnimationModels[client] = INVALID_ENT_REFERENCE;
	}
	StopSound(client, CONGA_SNDCHAN, CONGA_SND);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	return Plugin_Handled;
}

SetMiscsRender(client, RenderMode:RMode) {
	if(IsPlayerAlive(client)) {
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable")) != -1) {
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2) {
				SetEntityRenderMode(wearable, RMode);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable_item_demoshield")) != -1) {
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2) {
				SetEntityRenderMode(wearable, RMode);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1) {
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2) {
				SetEntityRenderMode(wearable, RMode);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1) {
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2) {
				SetEntityRenderMode(wearable, RMode);
			}
		}
	}
}