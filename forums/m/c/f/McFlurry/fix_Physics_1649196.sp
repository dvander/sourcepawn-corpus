#define PLUGIN_VERSION "1.0"
/*
=====================================================================================================================
=====================================================================================================================
211_1_1____2¶¶¶¶66¶¶¶¶¶¶¶88¶88__¶888¶¶2________126
__________¶¶¶¶¶12¶¶¶¶¶8¶¶¶866¶612¶8¶¶¶6_1_________
211_1___6¶¶¶¶¶¶¶¶¶¶¶¶¶¶866¶¶66¶822¶¶8886681_______
1111____2¶¶¶¶¶¶¶¶¶¶¶¶¶¶8688¶¶8_8¶2168¶61126_______  					
21___268¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶8¶¶¶¶¶¶68¶6_188__666______
11__12¶¶¶¶¶¶228¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶68¶2_26¶2_2861____     ___           _  _              _             _   _         
1__16¶¶¶¶¶6___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶61¶¶_¶¶6¶____122__    /   \ ___   __| |(_)  ___  __ _ | |_  ___   __| | | |_  ___  
1__8¶¶¶¶¶6____6¶¶¶¶8¶¶¶¶¶¶¶¶¶¶¶¶218¶18¶61¶1______1 	 / /\ // _ \ / _` || | / __|/ _` || __|/ _ \ / _` | | __|/ _ \ 
2186¶¶¶¶2_1____28682¶8¶8¶¶¶¶¶¶¶¶¶_68266¶1_2¶1_____ 	/ /_//|  __/| (_| || || (__| (_| || |_|  __/| (_| | | |_| (_) |
6862¶¶¶¶__1_____6___26_16¶8¶¶¶8__¶211612¶8_¶¶81886 /___,'  \___| \__,_||_| \___|\__,_| \__|\___| \__,_|  \__|\___/ 
¶88¶¶¶¶81_1____12________________¶¶1_11_6¶_2¶¶2___  _    _                                                     
6¶¶¶¶¶¶6__2____1________________2_88_2_1_¶1¶8661__ | |_ | |__    ___   _ __ ___    ___  _ __ ___    ___   _ __  _   _ 
1_¶¶¶¶¶2__8______________________1¶22____¶688¶¶12_ | __|| '_ \  / _ \ | '_ ` _ \  / _ \| '_ ` _ \  / _ \ | '__|| | | |
_2¶¶¶¶¶8__21_1_11_____________1__¶__11_1_¶81¶¶¶1__ | |_ | | | ||  __/ | | | | | ||  __/| | | | | || (_) || |   | |_| |
_2¶¶¶¶¶¶1_2621_1________________18___26__2¶2_¶¶___  \__||_| |_| \___| |_| |_| |_| \___||_| |_| |_| \___/ |_|    \__, |
28_¶¶¶¶¶1__262_____1_______1_____2___1611_8¶126___                                                               |___/
8__¶¶¶¶¶2_282_______________1____2___62_2__2¶¶6___                                 __ 
__2¶8¶8¶6_6¶¶¶8182______________622__16__12__82___                          ___   / _|
__¶2_2¶¶¶_6¶¶¶¶¶¶¶¶12__61_2¶¶¶¶¶¶¶¶66_6___¶¶21112_                         / _ \ | |_ 
1_81__8¶¶__6¶¶268¶¶¶¶61¶¶¶¶¶¶¶2_18¶¶1__1_2¶¶¶2_1_1                        | (_) ||  _|
8_22__1¶¶1__6¶¶¶¶¶¶¶¶_____¶¶¶¶¶¶¶_1¶____1¶¶¶¶8____                         \___/ |_| 
1_22__1¶¶8____6¶¶¶2__________81___6______¶¶¶¶¶2___
_______¶¶¶2_______________________2______626¶¶6___
_______8¶¶6_______16__________________1__¶¶¶¶8¶81_  						  *****
_____686¶¶¶¶2___12______________________¶¶¶¶8¶¶¶86
___2¶¶¶¶8¶¶¶6_____26_______________16___¶¶¶¶¶¶¶¶¶6          __  __                     __     __     
86¶¶¶¶¶¶¶¶¶¶¶¶221__2¶881__________22_____¶¶¶¶¶128¶         /\ \/\ \                   /\ \__ /\ \     
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶882_16_____¶¶¶21____1_1¶¶¶¶¶228¶         \ \ \_\ \      __      __  \ \ ,_\\ \ \___    
¶¶¶¶¶¶¶¶8¶¶¶¶8¶¶¶8¶¶¶¶¶¶¶¶¶62¶¶¶8___2___¶¶¶¶¶¶86¶¶          \ \  _  \   /'__`\  /'__`\ \ \ \/ \ \  _ `\  
¶¶¶¶¶¶¶¶¶¶¶¶¶8162__6¶¶¶¶¶¶66_______6____¶¶¶¶¶¶66¶¶           \ \ \ \ \ /\  __/ /\ \L\.\_\ \ \_ \ \ \ \ \
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶66___88¶88________¶¶____¶¶¶¶¶¶862¶¶            \ \_\ \_\\ \____\\ \__/.\_\\ \__\ \ \_\ \_\
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶6¶1____________¶¶¶1___¶¶¶¶¶¶¶¶626¶             \/_/\/_/ \/____/ \/__/\/_/ \/__/  \/_/\/_/
¶¶¶¶¶¶¶8¶¶¶¶¶2¶8¶¶¶2_________2¶81___2¶¶¶¶¶¶¶¶86618          __                  __                        
¶¶¶¶¶¶8¶¶¶¶¶¶2¶¶¶¶8¶¶¶8¶622¶¶¶_____6¶¶¶¶¶8¶¶¶8288¶         /\ \                /\ \                         
¶¶¶¶¶¶¶¶¶¶¶8¶¶8888¶628¶¶¶¶¶2¶¶6____1¶¶¶¶¶8¶¶¶8¶¶¶¶         \ \ \         __    \_\ \      __       __   _ __  
¶¶¶¶¶¶¶¶6¶¶8¶¶2666866¶¶¶¶¶¶_¶¶¶____6¶¶¶¶¶8¶¶68¶¶8¶          \ \ \  __  /'__`\  /'_` \   /'_ `\   /'__`\/\`'__\
¶¶¶¶¶¶¶¶68¶6¶¶668628¶¶¶¶¶¶82¶¶¶¶__1¶¶¶¶¶62¶¶68¶¶88           \ \ \L\ \/\  __/ /\ \L\ \ /\ \L\ \ /\  __/\ \ \/ 
¶¶¶¶¶¶¶¶6¶¶¶¶¶¶6666¶¶¶8¶2118¶¶¶¶6_8¶¶¶¶¶128¶6¶¶¶¶¶            \ \____/\ \____\\ \___,_\\ \____ \\ \____\\ \_\ 
¶¶¶¶¶¶¶¶¶¶¶88¶¶862¶¶¶8¶¶2826¶¶¶¶¶¶¶¶66¶¶16¶¶¶¶¶¶¶8             \/___/  \/____/ \/__,_ / \/___L\ \\/____/ \/_/ 
¶¶¶¶¶¶¶¶8¶¶¶2¶¶¶8¶¶¶28¶¶¶¶_2¶¶¶8¶¶¶22¶¶618¶¶¶¶¶¶¶¶                           	    	  /\____/             
¶¶¶¶¶¶¶¶82¶¶28¶¶¶¶8_28¶¶¶2__¶881_¶618¶¶12¶¶¶¶¶¶¶¶¶                            			  \_/__/      
=====================================================================================================================
=====================================================================================================================
 
												===< NOTE >===
 - When created (oxygentank, propanetank, fireworkcrate) change entnity class to prop_physics, now it can be exploded! You not more need to pickup it to explode. All plugins use cheat commands to spawn them is why you will never able to blow up them ^_^

 - Timer: When created entnity change class after x.x sec, better value [0.01], change the value to [1],[2] if you use the console to create (oxygentank, propanetank, fireworkcrate)

 - BarrowFix: This Addons VPK bug when WheelBarrow explodes like propane tank, set value to [0] if it bug never happens.
*/
#include <sourcemod>
#include <sdktools>
#pragma	semicolon 1

/*=====< debug >=====*/
#define debug 0 // on,off
#if debug
#endif

/*=====================
	   < Models >
=======================*/
#define	OxygenTank		"models/props_equipment/oxygentank01.mdl"
#define	Firework		"models/props_junk/explosive_box001.mdl"
#define	PropaneTank	"models/props_junk/propanecanister001a.mdl"
#define WheelBarrow	"models/props_junk/wheebarrow01a.mdl"

#define	Ent1			"weapon_oxygentank"
#define	Ent2			"weapon_fireworkcrate"
#define	Ent3			"weapon_propanetank"
#define	Ent				"prop_physics"

/*=====================
	   < ConVar >
=======================*/
new		Handle:g_Physics, Handle:g_Timer;

new 	g_CvarPhysics, w;

new		Float:g_CvarTimer;

new		String:Models[64], String:vModels[64];

new		bool:hook;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Physics",
	author = "raziEiL [disawar1]",
	description = "Сhange of entity class.",
	version = PLUGIN_VERSION,
	url = "http://l4d.darkmental.ru"
}

public OnPluginStart()
{
	CreateConVar("physics_version", PLUGIN_VERSION, "Physics plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Physics		=	CreateConVar("physics_barrow", "0", "1: Enable exloded WheelBarrow fix, 0: Disable", FCVAR_PLUGIN);
	g_Timer			=	CreateConVar("physics_timer", "0.01", "When created entnity change class after x.x sec", FCVAR_PLUGIN, true, 0.01, true, 2.0);
	AutoExecConfig(true, "fix_Physics");
	
	HookConVarChange(g_Physics, OnCVarChange);
	HookConVarChange(g_Timer, OnCVarChange);
	
	RegAdminCmd("physics", CmdPhysics, ADMFLAG_KICK); // test cmd create physics entity
}

/*=====================
		< Cmd >
=======================*/
public Action:CmdPhysics(client, agrs)
{
	if (client > 0){
	
		if (agrs == 1){
			decl String:Agr[16];
			GetCmdArgString(Agr, sizeof(Agr));
			
			if (strcmp(Agr, "1") == 0 || strcmp(Agr, "2") == 0 || strcmp(Agr, "3") == 0){
				decl Float:Pos[3], Float:Eye[3], String:x[64];
				new Float:distance = 50.0;
				
				GetClientFrontLocation(client, Pos, Eye, distance);
				
				if (strcmp(Agr, "1") == 0)
					Format(x, sizeof(x), PropaneTank);
				if (strcmp(Agr, "2") == 0)
					Format(x, sizeof(x), OxygenTank);
				if (strcmp(Agr, "3") == 0)
					Format(x, sizeof(x), Firework);
					
				hook=false;
				new ent = CreateEntityByName("prop_physics");
				hook=true;
				if (ent != -1 && IsValidEdict(ent) && IsValidEntity(ent)){
					DispatchKeyValue(ent, "model", x);
					DispatchSpawn(ent);
					TeleportEntity(ent, Pos, Eye, NULL_VECTOR);
					PrintToChatAll("[Physics] created <%s>", x);
				}
			}
		}
	}
	return Plugin_Handled;
}

GetClientFrontLocation(client, Float:position[3], Float:angles[3], Float:distance = 50.0 )
{
	if (client > 0){
	
		decl Float:Origin[3], Float:Angles[3], Float:Direction[3];
		
		GetClientAbsOrigin(client, Origin);
		GetClientEyeAngles(client, Angles);
		GetAngleVectors(Angles, Direction, NULL_VECTOR, NULL_VECTOR );
		
		position[0] = Origin[0] + Direction[0] * distance;
		position[1] = Origin[1] + Direction[1] * distance;
		position[2] = Origin[2];
		
		angles[0] = 0.0;
		angles[1] = Angles[1];
		angles[2] = 0.0;
	}
}
/*										+==========================================+
										|		  Classname Name Changer		   |
										|							[prop_physics] |
										+==========================================+	
*/
public OnMapEnd()
{
	hook=false;
}

public OnClientPostAdminCheck(client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && hook == false)
		hook=true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity != -1 && IsValidEdict(entity) && IsValidEntity(entity)){

		if (g_CvarPhysics == 1 && strcmp(classname, Ent) == 0) CreateTimer(0.01, Timer, entity);
		
		if (hook == true){
		
			if (strcmp(classname, Ent1) == 0 || 
				strcmp(classname, Ent2) == 0 || 
				strcmp(classname, Ent3) == 0){
				
				w=-1;
	
				#if debug
				PrintToChatAll("entity created <%s>", classname);
				#endif
				
				if (strcmp(classname, Ent1) == 0)
					Format(Models, sizeof(Models), OxygenTank);
				if (strcmp(classname, Ent2) == 0)
					Format(Models, sizeof(Models), Firework);
				if (strcmp(classname, Ent3) == 0)
					Format(Models, sizeof(Models), PropaneTank);
				
				CreateTimer(g_CvarTimer, Timer, entity);
			}
		}
	}
}

public Action:Timer(Handle:timer, any:entity)
{
	if (entity != -1 && IsValidEdict(entity) && IsValidEntity(entity)){
				
		if (g_CvarPhysics == 1 && w !=-1){
	
			if (entity == w){
			
				#if debug
				LogMessage("Ent Id %d=%d, block cycle!", entity, w);
				#endif
	
				return;
			}

			GetEntPropString(entity, Prop_Data, "m_ModelName", vModels, sizeof(vModels));

			if (strcmp(vModels, WheelBarrow) == 0){

				Format(Models, sizeof(Models), WheelBarrow);
				
				#if debug
				LogMessage("Valve Model <%s> created", Models);
				#endif
			}
			else return;
		}
		
		decl Float:Origin[3], Float:Angeles[3];
		
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
		if (Origin[0] == 0 && Origin[1] == 0 && Origin[2] == 0) return;
		
		GetEntPropVector(entity, Prop_Send, "m_angRotation", Angeles);
		AcceptEntityInput(entity, "Kill");
		
		new ent;
		if (w == -1)
			ent = CreateEntityByName(Ent);
		else 
			ent = CreateEntityByName("prop_physics_override");
		
		if (ent != -1 && IsValidEdict(entity) && IsValidEntity(entity)){
			DispatchKeyValue(ent, "model", Models);
			DispatchSpawn(ent);
			TeleportEntity(ent, Origin, Angeles, NULL_VECTOR);
			
			w=ent;
			#if debug
			PrintToChatAll("entity re-created %f %f %f", Origin[0], Origin[1], Origin[2]);
			LogMessage("entity re-created %f %f %f", Origin[0], Origin[1], Origin[2]);
			#endif
		}
	}
}

/*=====================
	< GetConVar >
=======================*/
public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

public GetCVars()
{
	g_CvarPhysics = GetConVarInt(g_Physics);
	g_CvarTimer = GetConVarFloat(g_Timer);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	
	if (!StrEqual(game, "left4dead", false) &&
		!StrEqual(game, "left4dead2", false) ||
		!IsDedicatedServer())
		return APLRes_Failure;
	return APLRes_Success;
}