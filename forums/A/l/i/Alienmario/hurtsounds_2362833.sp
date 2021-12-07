#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Player hurt sounds",
	author = "Alienmario",
	description = "Makes pain sounds when low hp",
	version = "1.0",
}

#define MAX_SOUND 20
new String:maleHurt[][32] = {
"vo/npc/male01/imhurt01.wav",
"vo/npc/male01/imhurt02.wav",
"vo/npc/male01/help01.wav",
"vo/npc/male01/hitingut01.wav",
"vo/npc/male01/hitingut02.wav",
"vo/npc/male01/myarm02.wav",
"vo/npc/male01/myarm01.wav",
"vo/npc/male01/mygut02.wav",
"vo/npc/male01/myleg01.wav",
"vo/npc/male01/myleg02.wav",
"vo/npc/male01/no01.wav",
"vo/npc/male01/no02.wav",
"vo/npc/male01/ow01.wav",
"vo/npc/male01/ow02.wav",
"vo/npc/male01/pain01.wav",
"vo/npc/male01/pain02.wav",
"vo/npc/male01/pain02.wav",
"vo/npc/male01/pain03.wav",
"vo/npc/male01/pain04.wav",
"vo/npc/male01/pain05.wav",
"vo/npc/male01/pain06.wav",
};

new String:femaleHurt[][32] = {
"vo/npc/female01/imhurt01.wav",
"vo/npc/female01/imhurt02.wav",
"vo/npc/female01/help01.wav",
"vo/npc/female01/hitingut01.wav",
"vo/npc/female01/hitingut02.wav",
"vo/npc/female01/myarm02.wav",
"vo/npc/female01/myarm01.wav",
"vo/npc/female01/mygut02.wav",
"vo/npc/female01/myleg01.wav",
"vo/npc/female01/myleg02.wav",
"vo/npc/female01/no01.wav",
"vo/npc/female01/no02.wav",
"vo/npc/female01/ow01.wav",
"vo/npc/female01/ow02.wav",
"vo/npc/female01/pain01.wav",
"vo/npc/female01/pain02.wav",
"vo/npc/female01/pain02.wav",
"vo/npc/female01/pain03.wav",
"vo/npc/female01/pain04.wav",
"vo/npc/female01/pain05.wav",
"vo/npc/female01/pain06.wav",
}

#define MAX_SOUND_COMBINE 3
new String:combineHurt[][37] = {
"npc/combine_soldier/pain1.wav",
"npc/combine_soldier/pain2.wav",
"npc/combine_soldier/pain3.wav",
"npc/combine_soldier/vo/coverhurt.wav",
}

#define MAX_SOUND_METRO 5
new String:metroHurt[][32] = {
"npc/metropolice/vo/help.wav",
"npc/metropolice/vo/shit.wav",
"npc/metropolice/pain1.wav",
"npc/metropolice/pain2.wav",
"npc/metropolice/pain3.wav",
"npc/metropolice/pain4.wav",
}

#define MAX_SOUND_BARNEY 14
new String:barneyHurt[][32] = {
"vo/npc/barney/ba_pain01.wav",
"vo/npc/barney/ba_pain02.wav",
"vo/npc/barney/ba_pain03.wav",
"vo/npc/barney/ba_pain04.wav",
"vo/npc/barney/ba_pain05.wav",
"vo/npc/barney/ba_pain06.wav",
"vo/npc/barney/ba_pain07.wav",
"vo/npc/barney/ba_pain08.wav",
"vo/npc/barney/ba_pain09.wav",
"vo/npc/barney/ba_pain10.wav",
"vo/npc/barney/ba_no01.wav",
"vo/npc/barney/ba_no02.wav",
"vo/npc/barney/ba_ohshit03.wav",
"vo/npc/barney/ba_wounded02.wav",
"vo/npc/barney/ba_wounded03.wav",
}

#define MAX_SOUND_MONK 14
new String:monkHurt[][32] = {
"vo/ravenholm/monk_pain01.wav",
"vo/ravenholm/monk_pain02.wav",
"vo/ravenholm/monk_pain03.wav",
"vo/ravenholm/monk_pain04.wav",
"vo/ravenholm/monk_pain05.wav",
"vo/ravenholm/monk_pain06.wav",
"vo/ravenholm/monk_pain07.wav",
"vo/ravenholm/monk_pain08.wav",
"vo/ravenholm/monk_pain09.wav",
"vo/ravenholm/monk_pain10.wav",
"vo/ravenholm/monk_pain12.wav",
"vo/ravenholm/monk_danger01.wav",
"vo/ravenholm/monk_helpme02.wav",
"vo/ravenholm/monk_helpme04.wav",
"vo/ravenholm/monk_helpme05.wav",
}

#define MAX_SOUND_ALYX 8
new String:alyxHurt[][32] = {
"vo/npc/alyx/uggh01.wav",
"vo/npc/alyx/uggh02.wav",
"vo/npc/alyx/hurt04.wav",
"vo/npc/alyx/hurt05.wav",
"vo/npc/alyx/hurt06.wav",
"vo/npc/alyx/hurt08.wav",
"vo/npc/alyx/gasp03.wav",
"vo/npc/alyx/gasp03.wav",
"vo/npc/alyx/gasp02.wav",
}

#define MAX_SOUND_KLEINER 4
new String:kleinerHurt[][32] = {
"vo/k_lab/kl_ahhhh.wav",
"vo/k_lab/kl_getoutrun03.wav",
"vo/k_lab/kl_hedyno03.wav",
"vo/k_lab/kl_ohdear.wav",
"vo/k_lab/kl_dearme.wav",
}

#define MAX_SOUND_BREEN 3
new String:breenHurt[][32] = {
"vo/citadel/br_failing11.wav",
"vo/citadel/br_no.wav",
"vo/citadel/br_ohshit.wav",
"vo/citadel/br_youneedme.wav",
}

bool played[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_hurt", player_hurt, EventHookMode_Post);
	CreateTimer(2.0, CheckHealthRaise, _, TIMER_REPEAT);
}

public OnMapStart(){
	for (new i=0; i<=MAX_SOUND; i++){
		PrecacheSound(maleHurt[i], true);
		PrecacheSound(femaleHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_ALYX; i++){
		PrecacheSound(alyxHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_MONK; i++){
		PrecacheSound(monkHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_BARNEY; i++){
		PrecacheSound(barneyHurt[i], true);
	}	
	for (new i=0; i<=MAX_SOUND_METRO; i++){
		PrecacheSound(metroHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_KLEINER; i++){
		PrecacheSound(kleinerHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_COMBINE; i++){
		PrecacheSound(combineHurt[i], true);
	}
	for (new i=0; i<=MAX_SOUND_BREEN; i++){
		PrecacheSound(breenHurt[i], true);
	}
}

public OnClientDisconnect(client){
	played[client]=false;
}

public player_death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(played[client]){
		played[client]=false;
	}
}

public Action:CheckHealthRaise(Handle:timer){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)){
			if(played[i] && GetClientHealth(i)>=45){
				played[i]=false;
			}
		}
	}
	return Plugin_Continue;
}

public player_hurt (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(played[client]) return;
	if(GetClientTeam(client)<2) return;
	
	new hp = GetEventInt(event, "health");
	if(hp<45 && hp>0){
		played[client]=true;
		
		char buffer[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
		if(StrContains(buffer, "female", false)!=-1 || StrContains(buffer, "mossman", false)!=-1){
			EmitSoundToAll(femaleHurt[GetRandomInt(0, MAX_SOUND)], client);
		} 
		else if (StrContains(buffer, "alyx", false)!=-1){
			EmitSoundToAll(alyxHurt[GetRandomInt(0, MAX_SOUND_ALYX)], client);
		}
		else if (StrContains(buffer, "combine", false)!=-1){
			EmitSoundToAll(combineHurt[GetRandomInt(0, MAX_SOUND_COMBINE)], client);
		}
		else if (StrContains(buffer, "police", false)!=-1){
			EmitSoundToAll(metroHurt[GetRandomInt(0, MAX_SOUND_METRO)], client);
		}	
		else if (StrContains(buffer, "barney", false)!=-1){
			EmitSoundToAll(barneyHurt[GetRandomInt(0, MAX_SOUND_BARNEY)], client);
		}
		else if (StrContains(buffer, "monk", false)!=-1){
			EmitSoundToAll(monkHurt[GetRandomInt(0, MAX_SOUND_MONK)], client);
		}
		else if (StrContains(buffer, "breen", false)!=-1){
			EmitSoundToAll(breenHurt[GetRandomInt(0, MAX_SOUND_BREEN)], client);
		}
		else if (StrContains(buffer, "kleiner", false)!=-1){
			EmitSoundToAll(kleinerHurt[GetRandomInt(0, MAX_SOUND_KLEINER)], client);
		}
		else{
			EmitSoundToAll(maleHurt[GetRandomInt(0, MAX_SOUND)], client);
		}
	}
}