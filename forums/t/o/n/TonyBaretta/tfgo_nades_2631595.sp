#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <keyvalues>
#define MAX_BUTTONS 26

#define VERSION "1.0"
#define FADE_IN	 0x0001
#define FADE_OUT 0x0002
#define exp_sound "weapons/flare_detonator_explode_world.wav"
#define stun_sound "ambient/lair/spawn_tone1.wav"
#define smoke_sound "weapons/flame_thrower_bb_start.wav"
#define fh_sound "vo/halloween_merasmus/sf12_grenades04.mp3"

#define SND_SHOOT			"weapons/grenade_launcher_shoot.wav"
#define SND_WARN			"misc/doomsday_lift_warning.wav"
#define MDL_MINIBOMB			"models/weapons/w_models/w_stickybomb.mdl"
#define MDL_FLASH 		"models/weapons/w_models/w_stickybomb3.mdl"
#define MDL_SMOKE 		"models/weapons/w_models/w_stickybomb2.mdl"

ConVar g_Cvar_TFGOEnabled;
ConVar g_AmmoTFGO;
ConVar g_cvar_rColor;
ConVar g_CvarTFGODist;
Handle TFGOHud;
int TFGOActiveWeapon[MAXPLAYERS+1] = -1;

bool TimeToExplode = false;
bool TimeToExplodeSound[MAXPLAYERS+1] = false;
int iTFGONade[MAXPLAYERS+1] = -1;
bool FirstSpawn[MAXPLAYERS+1];
int g_iPlayerLastButtons[MAXPLAYERS + 1];
public Plugin myinfo = 
{
	name = "TF2GO nades",
	author = "TonyBaretta",
	description = "TF2GO nades",
	version = VERSION,
	url = "https://www.wantedgov.it"
}
public OnMapStart()
{
	PrecacheSound(SND_SHOOT);
	PrecacheSound(SND_WARN);
	PrecacheModel(MDL_MINIBOMB);
	PrecacheModel(MDL_SMOKE);
	PrecacheModel(MDL_FLASH);
}
public void OnPluginStart()
{
	CreateConVar("tfgon_version", VERSION, "TFGOnade version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_TFGOEnabled = CreateConVar("TFGO_enabled", "1", "Enable TFGOnades?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvar_rColor = CreateConVar("TFGO_smoke_color_mode", "0", "0 grey, 1 random, 2 teamcolor", FCVAR_NONE);
	g_AmmoTFGO = CreateConVar("TFGO_ammo", "6", "number of TFGONades aviable ", FCVAR_NONE);
	g_CvarTFGODist = CreateConVar("TFGO_dist", "1000.0", "Distance from Flashbang to get flashed ", FCVAR_NONE);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	AddNormalSoundHook(view_as<NormalSHook>(ChangeSound));
	TFGOHud = CreateHudSynchronizer();
	AutoExecConfig(true, "tfgonades_cfg");
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(g_Cvar_TFGOEnabled.BoolValue){
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int iTFGOammo = g_AmmoTFGO.IntValue;
		if(IsValidClient(client)){
			if(g_Cvar_TFGOEnabled.BoolValue && FirstSpawn[client]){
				PrintToChat(client,"\x04[TFGO NADES] This Server is Running TFGO Nades !");
				FirstSpawn[client] = false;
			}
			SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
			int SpellB = FindSpellbook(client);
			if(SpellB == -1){
				ForceItems(client);
			}
			int ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
			{
				if(ent)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")==client)
					{
						SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
						SetEntProp(ent, Prop_Send, "m_iSpellCharges", iTFGOammo);
						PrintToChat(client,"\x04[TFGO NADES]\x02 Ammo Reloaded!");
					}
				}
			}
		}
	}
}
public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
	if(g_Cvar_TFGOEnabled.BoolValue){
		for (int i = 0; i < MAX_BUTTONS; i++)
		{
			int button = (1 << i);

			if ((buttons & button))
			{
				if (!(g_iPlayerLastButtons[iClient] & button))
				{
					ClientOnButtonPress(iClient, button);
				}
			}
			else if ((g_iPlayerLastButtons[iClient] & button))
			{
				ClientOnButtonRelease(iClient, button);
			}
		}
		g_iPlayerLastButtons[iClient] = buttons;
	}
	return Plugin_Continue;
}

public void ClientOnButtonPress(int iClient,int button)
{
	if (button == IN_ATTACK3)
	{
		KeyValues actionSlot = new KeyValues("use_action_slot_item_server");
		FakeClientCommandKeyValues(iClient, actionSlot);
		delete actionSlot;
	}
}
public void ClientOnButtonRelease(int iClient,int button)
{

}
public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_Cvar_TFGOEnabled.BoolValue && StrEqual(classname, "tf_projectile_spellfireball", false))
	{
		SDKHook(entity, SDKHook_Spawn, ProjectileSpell_OnSpawn);
	}
}
public Action ProjectileSpell_OnSpawn(int entity)
{
	if (IsValidEntity(entity))
	{
		float vPosition[3];
		float vAngles[3];
		float flSpeed = 1500.0;
		float vVelocity[3];
		float vBuffer[3];
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(owner)){
			GetClientEyePosition(owner, vPosition);
			GetClientEyeAngles(owner, vAngles);
			if(TFGOActiveWeapon[owner] == 2){
				CreateTimer(1.8, CheckForSmoke, owner);
			}
		}
		// Is the owner a player?
		if (owner > 0 && owner <= MaxClients)
		{
			AcceptEntityInput(entity, "Kill");
			if(TFGOActiveWeapon[owner] == 0){
				iTFGONade[owner] = CreateEntityByName("tf_projectile_pipe_remote");
				DispatchKeyValue(iTFGONade[owner], "targetname", "decoy");
			}
			if(TFGOActiveWeapon[owner] == 1){
				iTFGONade[owner] = CreateEntityByName("tf_projectile_pipe");
				DispatchKeyValue(iTFGONade[owner], "targetname", "flash");
			}
			if(TFGOActiveWeapon[owner] == 2){
				//CreateTimer(1.8, CheckForSmoke, owner);
				iTFGONade[owner] = CreateEntityByName("tf_projectile_stun_ball");
				DispatchKeyValue(iTFGONade[owner], "targetname", "smoke");
			}			
			if(IsValidEntity(iTFGONade[owner]))
			{					
				GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					
				vVelocity[0] = vBuffer[0]*flSpeed;
				vVelocity[1] = vBuffer[1]*flSpeed;
				vVelocity[2] = vBuffer[2]*flSpeed;
				SetEntPropVector(iTFGONade[owner], Prop_Data, "m_vecVelocity", vVelocity);
				if((TFGOActiveWeapon[owner] == 0) || (TFGOActiveWeapon[owner] == 1)){
					SetEntPropEnt(iTFGONade[owner], Prop_Send, "m_hThrower", owner);
				}
				if(TFGOActiveWeapon[owner] == 2){
					SetEntPropEnt(iTFGONade[owner], Prop_Send, "m_hOwnerEntity", owner);
				}
				SetEntProp(iTFGONade[owner], Prop_Send, "m_iTeamNum", GetClientTeam(owner));
				if(TFGOActiveWeapon[owner] == 0){
					SetVariantString("OnUser3 !self:FireUser4::3.5:1");
					AcceptEntityInput(iTFGONade[owner], "AddOutput");
					HookSingleEntityOutput(iTFGONade[owner], "OnUser4", Killnade, false);
					CreateTimer(0.8, Timer_minibombs, EntIndexToEntRef(iTFGONade[owner]));
				}
				if(TFGOActiveWeapon[owner] == 1){
					SetVariantString("OnUser3 !self:FireUser4::2.0:1");
					AcceptEntityInput(iTFGONade[owner], "AddOutput");
					HookSingleEntityOutput(iTFGONade[owner], "OnUser4", Killnade, false);
				}
				if(TFGOActiveWeapon[owner] == 2){
					SetVariantString("OnUser3 !self:FireUser4::4.0:1");
					AcceptEntityInput(iTFGONade[owner], "AddOutput");
					HookSingleEntityOutput(iTFGONade[owner], "OnUser4", Killnade, false);
				}
				AcceptEntityInput(iTFGONade[owner], "FireUser3");
				SetEntProp(iTFGONade[owner], Prop_Data, "m_nNextThinkTick", -1);
				DispatchSpawn(iTFGONade[owner]);
				if(TFGOActiveWeapon[owner] == 0){
					SetEntityModel(iTFGONade[owner], MDL_MINIBOMB);
				}
				if(TFGOActiveWeapon[owner] == 1){
					SetEntityModel(iTFGONade[owner], MDL_FLASH);
				}
				if(TFGOActiveWeapon[owner] == 2){
					SetEntityModel(iTFGONade[owner], MDL_SMOKE);
				}
				if(TFGOActiveWeapon[owner] == 1){
					CreateTimer(1.5, detonate, owner);
				}
				EmitSoundToClient(owner, "weapons/knife_swing.wav");
				SDKHook(iTFGONade[owner], SDKHook_Touch, OnTouchFlashNade);
				TeleportEntity(iTFGONade[owner], vPosition, vAngles, vVelocity);
				//CreateParticle(iTFGONade[owner], "xms_icicle_melt", true, 1.0);
				
				PrecacheSound(fh_sound, true);
				//EmitSoundToClient(owner, fh_sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
				EmitSoundToClient(owner, fh_sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
			}
		}
	}
}
public Action OnTouchFlashNade(int iEntity, int other)
{
	if(other && other <= MaxClients){
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 
public void Killnade(const char[] output, int caller, int activator, float delay){

	if(caller == -1){
		return;
	}
	AcceptEntityInput(caller, "Kill");
}
public Action Sound_Detonate(int iClient)
{
	if(IsValidClient(iClient)){
		PrecacheSound(exp_sound, true);
		EmitSoundToClient(iClient, exp_sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
		PrecacheSound(stun_sound, true);
		EmitSoundToClient(iClient, stun_sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
		TimeToExplodeSound[iClient] = false;
	}
}
public Action Sound_DetSmoke(int iClient)
{
	if(IsValidClient(iClient)){
		PrecacheSound(smoke_sound, true);
		EmitSoundToClient(iClient, smoke_sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO);
	}
}

public Action detonate(Handle timer, int iClient)
{
	TimeToExplode = true;
	TimeToExplodeSound[iClient] = true;
	CreateTimer(2.0, reset, iClient);
}
public Action reset(Handle timer, int iClient)
{
	TimeToExplode = false;
}

public Fade(iClient, duration, time, const color[4])
{
	if (IsValidClient(iClient))
	{
		Handle hBf=StartMessageOne("Fade", iClient);
		if(hBf!=INVALID_HANDLE)
		{
			BfWriteShort(hBf,duration);
			BfWriteShort(hBf,time);
			BfWriteShort(hBf,FADE_IN);
			BfWriteByte(hBf,color[0]);
			BfWriteByte(hBf,color[1]);
			BfWriteByte(hBf,color[2]);
			BfWriteByte(hBf,color[3]);
			EndMessage();
		}
	}
}
stock ForceItems (client)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, "tf_weapon_spellbook");
	TF2Items_SetItemIndex(hWeapon, 1069);
	TF2Items_SetLevel(hWeapon, 0);
	TF2Items_SetQuality(hWeapon, 0);

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
stock int FindSpellbook(int client)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))
		{
			return i;
		}
	}
	return -1;
}
/* public void OnGameFrame(){
	for (int i = 1; i < MaxClients; i++){
		float fCPosition[3], fEPosition[3], fDistance;

		if(TimeToExplode)
		{
			if(IsValidClient(i)){
				if (IsValidEntity(iTFGONade[i]))
				{
					GetEntPropVector(iTFGONade[i], Prop_Data, "m_vecOrigin", fCPosition);
				}
				for (int ii = 1; ii < MaxClients; ii++){
					GetEntPropVector(ii, Prop_Data, "m_vecOrigin", fEPosition);

					fDistance = GetVectorDistance(fCPosition, fEPosition);

					if (fDistance < g_CvarTFGODist.FloatValue){
						if(TimeToExplodeSound[ii]){
							Sound_Detonate(ii);
						}
						int color[4]={250,250,250,255};
						Fade(ii, 600, 600 , color);
					}
				}
			}
		}
		if(IsValidClient(i) && IsPlayerAlive(i)){
			int FlashNum = GetTFGONadesUses(i);
			SetHudTextParams(-1.5, 0.80, 0.30, 255, 255, 255, 255);
			if(TFGOActiveWeapon[i] == 0){
				ShowSyncHudText(i, TFGOHud, "Decoy Nade: %i", FlashNum);
			}
			if(TFGOActiveWeapon[i] == 1){
				ShowSyncHudText(i, TFGOHud, "Flashbang Nade: %i", FlashNum);
			}
			if(TFGOActiveWeapon[i] == 2){
				ShowSyncHudText(i, TFGOHud, "Smoke Nade Nade: %i", FlashNum);
			}
		}
	}
} */
public void OnGameFrame(){

	int iLiveNade = -1;
	while ((iLiveNade  = FindEntityByClassname(iLiveNade, "tf_projectile_pipe")) != -1)
	{
		char strName[50];
		GetEntPropString(iLiveNade, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "flash") >= 0){
			float fCPosition[3], fEPosition[3], fDistance;

			if(TimeToExplode)
			{
				if (IsValidEntity(iLiveNade))
				{
					GetEntPropVector(iLiveNade, Prop_Data, "m_vecOrigin", fCPosition);
				}
				for (int ii = 1; ii < MaxClients; ii++){
					if(IsValidClient(ii)){
						GetEntPropVector(ii, Prop_Data, "m_vecOrigin", fEPosition);
						fDistance = GetVectorDistance(fCPosition, fEPosition);

						if (fDistance < g_CvarTFGODist.FloatValue){
							if(TimeToExplodeSound[ii]){
								Sound_Detonate(ii);
							}
							int color[4]={250,250,250,255};
							Fade(ii, 600, 600 , color);
						}
					}
				}
			}
		}
	}
	for (int i = 1; i < MaxClients; i++){
		if(IsValidClient(i) && IsPlayerAlive(i)){
			int FlashNum = GetTFGONadesUses(i);
			SetHudTextParams(-1.0, 0.80, 0.30, 255, 255, 255, 255);
			if(TFGOActiveWeapon[i] == 0){
				ShowSyncHudText(i, TFGOHud, "Decoy Nade: %i", FlashNum);
			}
			if(TFGOActiveWeapon[i] == 1){
				ShowSyncHudText(i, TFGOHud, "Flashbang Nade: %i", FlashNum);
			}
			if(TFGOActiveWeapon[i] == 2){
				ShowSyncHudText(i, TFGOHud, "Smoke Nade Nade: %i", FlashNum);
			}
		}
	}
}
GetTFGONadesUses(client)
{
	int ent = FindSpellbook(client);
	if(!IsValidEntity(ent)) return 0;
	return GetEntProp(ent, Prop_Send, "m_iSpellCharges");
}
public Action Timer_minibombs(Handle timer, any entity)
{
	int ent = EntRefToEntIndex(entity);
	decl String:sClass[32];
	
	if (ent > 0 && ent > MaxClients && IsValidEntity(ent) && GetEntityClassname(ent, sClass, sizeof(sClass)))
	{
		if(StrEqual(sClass, "tf_projectile_pipe_remote") && GetEntProp(ent, Prop_Send, "m_bTouched") && GetEntProp(ent, Prop_Send, "m_iType") != 2)
		{
			int client = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
			int clientteam = GetClientTeam(client);			//Throwers team

			if(!CheckCommandAccess(client, "sm_minibombs_access", 0))
				return Plugin_Handled;
		
			float pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			
			float g_angles[3]; float g_angles2[3];		//Rotate sticky a bit when it shoots a bomblet
			GetEntPropVector(ent, Prop_Send, "m_angRotation", g_angles);

			g_angles2[0] = (g_angles[0] += GetRandomFloat(5.0,45.0));
			g_angles2[1] = (g_angles[1] += GetRandomFloat(5.0,45.0));
			g_angles2[2] = (g_angles[2] += GetRandomFloat(5.0,45.0));
			
			float ang[3];
			ang[0] = GetRandomFloat(-90.0, 90.0);			//Left, Right
			ang[1] = GetRandomFloat(-90.0, 90.0);			//Forward, Back
			ang[2] = GetRandomFloat(240.0, 340.0);			//Up, Down
			
			int pitch = 150;
			EmitAmbientSound(SND_SHOOT, pos, ent, _, _, _, pitch);
			
			int ent2 = CreateEntityByName("tf_projectile_pipe");
			
			if(ent2 != -1)
			{					
				SetEntPropEnt(ent2, Prop_Data, "m_hThrower", client);
				SetEntProp(ent2, Prop_Send, "m_iTeamNum", clientteam);
				SetEntProp(ent2, Prop_Send, "m_bCritical", true);
				SetEntPropFloat(ent2, Prop_Send, "m_flModelScale", 0.8);
				SetEntPropFloat(ent2, Prop_Send, "m_flDamage", 50.0);
				
				DispatchSpawn(ent2);
				
				SetEntityModel(ent2, MDL_MINIBOMB);
				
				TeleportEntity(ent2, pos, NULL_VECTOR, ang);							//Teleport bomblet to momma stickybomb
				TeleportEntity(ent, NULL_VECTOR, g_angles2, NULL_VECTOR);				//Rotate	
				
				CreateTimer(0.4, Timer_minibombs, EntRefToEntIndex(ent));		//The cycle continues..
			}
		}
	}
	return Plugin_Handled;
}
public Action OnWeaponSwitch(int iClient, int weapon)
{
	int primary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
	if (primary > -1 && primary == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"))
	{
		TFGOActiveWeapon[iClient] = 0;
	}  
	int secondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
	if (secondary > -1 && secondary == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"))
	{
		TFGOActiveWeapon[iClient] = 1;
	}
	int melee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
	if (melee > -1 && melee == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"))
	{
		TFGOActiveWeapon[iClient] = 2;
	}  
	
}
stock bool IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}
public Action CheckForSmoke(Handle timer, any iClient){
	int iLiveNade = -1;
	while ((iLiveNade  = FindEntityByClassname(iLiveNade, "tf_projectile_stun_ball")) != -1)
	{
		char strName[50];
		GetEntPropString(iLiveNade, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strName, "smoke") >= 0){
			int iTeam = GetClientTeam(iClient);
			CreateGas(iClient, iTeam, iLiveNade);
		}
	}		
}
public Action CreateGas(int iClient, int iTeam, int iEnt)
{
	float originpos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", originpos);
	char originData[64];
	Format(originData, sizeof(originData), "%f %f %f", originpos[0], originpos[1], originpos[2]);
	char colorData[64];
	if(g_cvar_rColor.IntValue == 0){
		Format(colorData, sizeof(colorData), "245 245 245");
	}
	if(g_cvar_rColor.IntValue == 1){
		int red = GetRandomInt(1, 255);
		int green = GetRandomInt(1, 255);
		int blue = GetRandomInt(1, 255);
		Format(colorData, sizeof(colorData), "%i %i %i", red, green, blue);
	}
	if(g_cvar_rColor.IntValue == 2){
		if(iTeam == 2){
			Format(colorData, sizeof(colorData), "255 0 0");
		}
		if(iTeam == 3){
			Format(colorData, sizeof(colorData), "0 0 255");
		}
	}
	
	// Create the Gas Cloud
	int gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"Origin", originData);
	DispatchKeyValue(gascloud,"BaseSpread", "100");
	DispatchKeyValue(gascloud,"SpreadSpeed", "70");
	DispatchKeyValue(gascloud,"Speed", "80");
	DispatchKeyValue(gascloud,"StartSize", "200");
	DispatchKeyValue(gascloud,"EndSize", "2");
	DispatchKeyValue(gascloud,"Rate", "40");
	DispatchKeyValue(gascloud,"JetLength", "400");
	DispatchKeyValue(gascloud,"Twist", "20");
	DispatchKeyValue(gascloud,"RenderColor", colorData);
	DispatchKeyValue(gascloud,"RenderAmt", "255");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	SetVariantString("OnUser3 !self:FireUser4::12.0:1");
	AcceptEntityInput(gascloud, "AddOutput");
	HookSingleEntityOutput(gascloud, "OnUser4", Killnade, false);
	AcceptEntityInput(gascloud, "FireUser3");
	AcceptEntityInput(gascloud, "TurnOn");
}
public Action ChangeSound(int clients[64], int numClients, char Pathname[PLATFORM_MAX_PATH], int client, int channel, float volume, int level, int pitch, int flags) 
{
	if(g_Cvar_TFGOEnabled.IntValue){
		if(StrContains(Pathname, "pl_impact_stun.wav", false) != -1)return Plugin_Stop;
		if(StrContains(Pathname, "sf13_spell_bombhead01.mp3", false) != -1) return Plugin_Stop;
		if(StrContains(Pathname, "pyro_sf13_spell_generic07.mp3", false) != -1)return Plugin_Stop;
		if(StrContains(Pathname, "spell_fireball_cast.wav", false) != -1)return Plugin_Stop;
		else
		return Plugin_Continue;
	}
	return Plugin_Continue;
}