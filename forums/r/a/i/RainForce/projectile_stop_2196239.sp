////Starting stuff
//Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//Info
public Plugin:myinfo = 
{
	name = "Projectile stop",
	author = "RainForce",
	version = "0.2.3",
	description = "Stops projectiles for laughs"
}
//ConVar Handles
new Handle:sm_stop_max_projectiles=INVALID_HANDLE;
new Handle:sm_stop_logs=INVALID_HANDLE;
new Handle:sm_stop_effects=INVALID_HANDLE;
new Handle:sm_stop_speed = INVALID_HANDLE;
new Handle:sm_stop_hook = INVALID_HANDLE;
new Handle:sm_stop_target = INVALID_HANDLE;
//Dynamic Array
new Handle:Projectiles=INVALID_HANDLE; //Made with dynamic array so that amount of max projectiles could be changed with a cvar mid-game
//bools
new bool:logs = false
//Plugin Start
public OnPluginStart()
{
	//Translations
	LoadTranslations("common.phrases")
	//Cvars
	sm_stop_max_projectiles = CreateConVar("sm_stop_max_projectiles","30","Maximum projectile allowed per client. Warning! Changing during game will make a for-loop release all the possible projectile that client indexes from 1 to MAXPLAYERS would have. tl;dr might get a lagspike",FCVAR_NOTIFY)
	sm_stop_logs = CreateConVar("sm_stop_logs","0","Do we spastically log everything?",FCVAR_NOTIFY)
	sm_stop_effects = CreateConVar("sm_stop_effects","1","Do we allow creation of tank-explosion at the end of each projectile?",FCVAR_NOTIFY)
	sm_stop_speed = CreateConVar("sm_stop_speed","1100.0","Speed that projectiles get after stopping",FCVAR_NOTIFY)
	sm_stop_hook = CreateConVar("sm_stop_hook","1","Hook type 1 = click-release; 2 = hold-release; Other numbers will be set to 1",FCVAR_NOTIFY)
	sm_stop_target = CreateConVar("sm_stop_target","0","Do togglers (stop_boom and stop) allow targetting?",FCVAR_NOTIFY)
	//Cvar Change Hook
	HookConVarChange(sm_stop_logs,CvarChanged)
	HookConVarChange(sm_stop_max_projectiles,CvarChanged)
	HookConVarChange(sm_stop_effects,CvarChanged)
	//Commands
	//On and Off versions can always target and don't set toggle; added for convenience when using @all and such
	RegAdminCmd("sm_stop",toggler,ADMFLAG_GENERIC,"Enables/Disables projectile stopper")
	RegAdminCmd("sm_stop_on",enable,ADMFLAG_GENERIC,"Enables projectile stopper")
	RegAdminCmd("sm_stop_off",disable,ADMFLAG_GENERIC,"Disables projectile stopper")
	RegAdminCmd("sm_stop_boom",boomtoggle,ADMFLAG_GENERIC,"Enables/Disables extra pimping effects")
	RegAdminCmd("sm_stop_boom_on",boomenable,ADMFLAG_GENERIC,"Enables extra pimping effects")
	RegAdminCmd("sm_stop_boom_off",boomdisable,ADMFLAG_GENERIC,"Disables extra pimping effects")
	RegAdminCmd("sm_stop_menu",classmenu,ADMFLAG_RCON,"Menu to choose what effects to add")
	RegAdminCmd("sm_stop_add",addtomenu,ADMFLAG_RCON,"Add stuff to menu (Don't use if you don't know what <entity classname> means")
	//Dynamic array for holding projectile
	Projectiles = CreateArray(GetConVarInt(sm_stop_max_projectiles),MAXPLAYERS)
	logs = GetConVarBool(sm_stop_logs);
	//Autoconfig
	AutoExecConfig(true,"stopper")
}
////Variables
//Arrays
new bool:InUse[MAXPLAYERS+1]
new bool:Effect[MAXPLAYERS+1]
//Menu Handles
new Handle:Menu=INVALID_HANDLE;
////Events
//Adding to menu of doom
public Action:addtomenu(client,args)
{
	if (args<2)
	{
		ReplyToCommand(client,"Usage sm_stop_add <name> <classname>")
		return Plugin_Handled;
	}
	new String:Path[PLATFORM_MAX_PATH]
	new Handle:Classes=INVALID_HANDLE;
	new String:Val[128]
	new bool:used=false
	new String:arg1[32]
	new String:arg2[64]
	
	GetCmdArg(1,arg1,sizeof(arg1))
	GetCmdArg(2,arg2,sizeof(arg2))
	BuildPath(Path_SM,Path,sizeof(Path),"configs/Valid spawn classes.txt")
	if (!FileExists(Path))
	{
		CloseHandle(OpenFile(Path,"w")) //Create the file if it doesn't exist
	}
	Classes=CreateKeyValues("Classes")
	FileToKeyValues(Classes,Path)
	KvJumpToKey(Classes,"Saved Classes",true)
	KvGotoFirstSubKey(Classes,false)
	do //Check if input classname already exists; I would have checked against name, but it is classname that matters
	{
		KvGetString(Classes,NULL_STRING,Val,sizeof(Val),"nil")
		if (StrEqual(Val,arg2,false))
		{
			used=true
			break;
		}
	}
	while (KvGotoNextKey(Classes,false))
	if (used) //If input classname already exists don't add it
	{
		if (logs) LogAction(-1,-1,"Same name was entered - %s!",arg1)
		ReplyToCommand(client,"such a name already exists!")
	}
	else //If it doesn't, rewind back to Saved Classes, and add it. Add - OFF to name tag
	{
		KvRewind(Classes)
		KvJumpToKey(Classes,"Saved Classes")
		if (logs) LogAction(-1,-1,"Saving %s as %s",arg2,arg1)
		Format(arg1,sizeof(arg1),"%s - OFF",arg1)
		KvSetString(Classes,arg1,arg2)
	}
	KvRewind(Classes) //Rewing back and save
	KeyValuesToFile(Classes,Path)
	CloseHandle(Classes)
	return Plugin_Handled;
}
//Menu of doom
public Action:classmenu(client,args)
{
	if (Menu!=INVALID_HANDLE)
	{
		CloseHandle(Menu) //If menu was for some reason not closed
	}
	new String:Path[PLATFORM_MAX_PATH]
	new Handle:Classes=INVALID_HANDLE;
	new String:Val[128]
	new String:name[MAX_NAME_LENGTH]
	new String:info[64]
	new String:key[32]
	
	BuildPath(Path_SM,Path,sizeof(Path),"configs/Valid spawn classes.txt")
	if (!FileExists(Path))
	{
		CloseHandle(OpenFile(Path,"w"))
	}
	Classes=CreateKeyValues("Classes")
	Menu=CreateMenu(MenuHandler)
	FileToKeyValues(Classes,Path)
	KvJumpToKey(Classes,"Saved Classes",true)
	KvGotoFirstSubKey(Classes,false)
	/* Running through whole of Saved Classes section;
	if name did not have - ON or - OFF tag we add -OFF tag
	then we add it to the Menu
	*/
	do
	{
		KvGetSectionName(Classes,key,sizeof(key))
		if (StrContains(key,"OFF")==-1&&StrContains(key,"ON")==-1)
		{
			if (logs) LogAction(-1,-1,"Chaging %s to %s - OFF",key,key)
			Format(key,sizeof(key),"%s - OFF",key)
			KvSetSectionName(Classes,key)
		}
		if (logs) LogAction(-1,-1,"Got %s under %s",Val,key)
		AddMenuItem(Menu,key,key)
	}
	while (KvGotoNextKey(Classes,false))
	if (logs) LogAction(-1,-1,"Got to the end of Saved Classes")
	KvRewind(Classes) //Rewind and save; in case we had to create the file, or added a tag
	KeyValuesToFile(Classes,Path)
	if (IsAClient(client)&&GetMenuItem(Menu,0,info,sizeof(info))) //If the menu is about to be shown to a valid player and has at least on option
	{
		GetClientName(client,name,sizeof(name))
		SetMenuTitle(Menu,"Choose wisely, %s",name)
		DisplayMenu(Menu,client,MENU_TIME_FOREVER)
	}
	else //If not, close it and pretend nothing ever happened
	{
		CloseHandle(Menu)
		Menu=INVALID_HANDLE;
	}
	CloseHandle(Classes)
	return Plugin_Handled;
}
//Handler of ^
public MenuHandler(Handle:menu,MenuAction:action,param1,param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			if (param1!=0) //If it was not because something was selected
			{
				CloseHandle(Menu)
				Menu=INVALID_HANDLE;
			}
		}
		case MenuAction_Select:
		{
			new String:info[32]
			new String:Path[PLATFORM_MAX_PATH]
			new Handle:Classes=INVALID_HANDLE;
			new String:Val[128]
			
			GetMenuItem(Menu,param2,info,sizeof(info))
			if (logs) LogAction(-1,-1,"%i selected N%i : %s",param1,param2,info)
			BuildPath(Path_SM,Path,sizeof(Path),"configs/Valid spawn classes.txt")
			Classes=CreateKeyValues("Classes")
			FileToKeyValues(Classes,Path)
			KvJumpToKey(Classes,"Saved Classes")
			KvGetString(Classes,info,Val,sizeof(Val)) //Since everything that is in a menu was taken from the file it should be in it; so no need for checks (Unless someone deletes the file <:O
			KvDeleteKey(Classes,info) //Deleting the file so that we can save it later with a new tag; this is faster than running through whole section searching for the correct key
			if (logs) LogAction(-1,-1,"Val is %s under %s",Val,info)
			if (ReplaceString(info,sizeof(info),"- OFF","- ON")!=0) //If it could replace OFF with ON
			{	
				RemoveMenuItem(Menu,param2)
				InsertMenuItem(Menu,param2,info,info)
				if (GetMenuItemCount(Menu)==param2) //If it was the last item in the menu, then we add it instead of inserting it since that won't work
				{
					AddMenuItem(Menu,info,info)
				}
				if (logs) LogAction(-1,-1,"Replaced OFF with ON; info is now %s",info)
			}
			else
			{
				ReplaceString(info,sizeof(info),"- ON","- OFF")
				RemoveMenuItem(Menu,param2)
				InsertMenuItem(Menu,param2,info,info)
				if (GetMenuItemCount(Menu)==param2)
				{
					AddMenuItem(Menu,info,info)
				}
				if (logs) LogAction(-1,-1,"Replaced ON with OFF; info is now %s",info)
			}
			KvSetString(Classes,info,Val) //Save it with a new tag
			KvRewind(Classes)
			KeyValuesToFile(Classes,Path)
			DisplayMenu(Menu,param1,MENU_TIME_FOREVER) //Display menu again
			CloseHandle(Classes)
		}
	}
}
//Cvar Change
public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	logs = GetConVarBool(sm_stop_logs);
	if (cvar==sm_stop_max_projectiles) 
	{
		if (logs)
		{
			LogAction(-1,-1,"Changing from %i to %i",StringToInt(oldVal),StringToInt(newVal))
		}
		for (new a=1;a<=MaxClients;a++)
		{
			Release(a,StringToInt(oldVal)) //Release all the old Projectiles on all clients; there is a check inside of Release() so no need to check here
		}
		Projectiles = INVALID_HANDLE;
		Projectiles = CreateArray(GetConVarInt(sm_stop_max_projectiles),MAXPLAYERS)
	}
	if (cvar==sm_stop_effects)
	{
		for (new i=1;i<MAXPLAYERS;i++)
		{
			Effect[i]=false
		}
	}
}
//Effect Toggle
public Action:boomtoggle(client,args)
{
	if (GetConVarBool(sm_stop_target)) //Check if it is a client only toggle or we could target
	{
		new Targs[MaxClients]
		if (args>=1) //If there was an argument then we run search
		{
			new String:arg1[MAX_NAME_LENGTH]
			new targs
			new String:target_name[MAX_NAME_LENGTH]
			new bool:tn_is_ml
			GetCmdArg(1,arg1,sizeof(arg1))
			if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
			{
				ReplyToTargetError(client,targs)
				return Plugin_Handled;
			}
		}
		for (new i=0;i<MaxClients;i++)
		{
			if (args<1&&i==0)
			{
				Targs[0]=client //If there was no argument set first cell in array to the person who ran the command
			}
			client=Targs[i]
			if (IsAClient(client))
			{
				if (Effect[client]==false)
				{
					if (logs) LogAction(-1,-1,"Turning pimping mode ON for %i",client)
					Effect[client]=true
					ReplyToCommand(client,"Pimping is now ON")
				}
				else
				{
					if (logs) LogAction(-1,-1,"Turning pimping mode OFF for %i",client)
					Effect[client]=false
					ReplyToCommand(client,"Pimping is now OFF")
				}
			}
		}
	}
	else
	{
		if (IsAClient(client))
		{
			if (Effect[client]==false)
			{
				if (logs) LogAction(-1,-1,"Turning pimping mode ON for %i",client)
				Effect[client]=true
				ReplyToCommand(client,"Pimping is now ON")
			}
			else
			{
				if (logs) LogAction(-1,-1,"Turning pimping mode OFF for %i",client)
				Effect[client]=false
				ReplyToCommand(client,"Pimping is now OFF")
			}
		}
	}
	return Plugin_Handled;
}
//Effect enable
public Action:boomenable(client,args)
{
	new Targs[MaxClients]
	if (args>=1)
	{
		new String:arg1[64]
		new targs
		new String:target_name[32]
		new bool:tn_is_ml
		GetCmdArg(1,arg1,sizeof(arg1))
		if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
		{
			ReplyToTargetError(client,targs)
			return Plugin_Handled;
		}
	}
	if (args<1)
	{
		Targs[0]=client
	}
	if (IsAClient(client))
	{
		for (new i=0;i<MaxClients;i++)
		{
			client=Targs[i]
			if (IsAClient(client))
			{
				if (logs) LogAction(-1,-1,"Turning pimping mode ON for %i",client)
				Effect[client]=true
				ReplyToCommand(client,"Pimping is now ON")
			}
		}
	}
	return Plugin_Handled;
}
//Effect disable
public Action:boomdisable(client,args)
{
	new Targs[MaxClients]
	if (args>=1)
	{
		new String:arg1[64]
		new targs
		new String:target_name[32]
		new bool:tn_is_ml
		GetCmdArg(1,arg1,sizeof(arg1))
		if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
		{
			ReplyToTargetError(client,targs)
			return Plugin_Handled;
		}
	}
	if (args<1)
	{
		Targs[0]=client
	}
	if (IsAClient(client))
	{
		for (new i=0;i<MaxClients;i++)
		{
			client=Targs[i]
			if (IsAClient(client))
			{
				if (logs) LogAction(-1,-1,"Turning pimping mode OFF for %i",client)
				Effect[client]=false
				ReplyToCommand(client,"Pimping is now OFF")
			}
		}
	}
	return Plugin_Handled;
}
//toggle
public Action:toggler(client,args)
{
	if (GetConVarBool(sm_stop_target))
	{
		new Targs[MaxClients]
		if (args>=1)
		{
			new String:arg1[64]
			new targs
			new String:target_name[32]
			new bool:tn_is_ml
			GetCmdArg(1,arg1,sizeof(arg1))
			if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
			{
				ReplyToTargetError(client,targs)
				return Plugin_Handled;
			}
		}
		if (args<1)
		{
			Targs[0]=client
		}
		for (new i=0;i<MaxClients;i++)
		{
			client=Targs[i]
			if (IsAClient(client))
			{
				if (InUse[client]==false)
				{
					if (logs) LogAction(-1,-1,"Turning stopping mode ON for %i",client)
					InUse[client]=true
					ReplyToCommand(client,"It is now ON")
				}
				else
				{
					if (logs) LogAction(-1,-1,"Turning stop mode OFF for %i",client)
					Release(client)
					InUse[client]=false
					ReplyToCommand(client,"It is now OFF")
				}
			}
		}
	}
	else
	{
		if (IsAClient(client))
		{
			if (InUse[client]==false)
			{
				if (logs) LogAction(-1,-1,"Turning stopping mode ON for %i",client)
				InUse[client]=true
				ReplyToCommand(client,"It is now ON")
			}
			else
			{
				if (logs) LogAction(-1,-1,"Turning stop mode OFF for %i",client)
				Release(client)
				InUse[client]=false
				ReplyToCommand(client,"It is now OFF")
			}
		}
	}
	return Plugin_Handled;
}
//enabler
public Action:enable(client,args)
{
	new Targs[MaxClients]
	if (args>=1)
	{
		new String:arg1[64]
		new targs
		new String:target_name[32]
		new bool:tn_is_ml
		GetCmdArg(1,arg1,sizeof(arg1))
		if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
		{
			ReplyToTargetError(client,targs)
			return Plugin_Handled;
		}
	}
	if (args<1)
	{
		Targs[0]=client
	}
	if (IsAClient(client))
	{
		for (new i=0;i<MaxClients;i++)
		{
			client=Targs[i]
			if (IsAClient(client))
			{
					if (logs) LogAction(-1,-1,"Turning stopping mode ON for %i",client)
					InUse[client]=true
					ReplyToCommand(client,"It is now ON")
			}
		}
	}
	return Plugin_Handled;
}
//Disabler
public Action:disable(client,args)
{
	new Targs[MaxClients]
	if (args>=1)
	{
		new String:arg1[64]
		new targs
		new String:target_name[32]
		new bool:tn_is_ml
		GetCmdArg(1,arg1,sizeof(arg1))
		if ((targs=ProcessTargetString(arg1,client,Targs,MaxClients,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml))<=0)
		{
			ReplyToTargetError(client,targs)
			return Plugin_Handled;
		}
	}
	if (args<1)
	{
		Targs[0]=client
	}
	if (IsAClient(client))
	{
		for (new i=0;i<MaxClients;i++)
		{
			client=Targs[i]
			if (IsAClient(client))
			{
					if (logs) LogAction(-1,-1,"Turning stopping mode OFF for %i",client)
					Release(client)
					InUse[client]=false
					ReplyToCommand(client,"It is now OFF")
			}
		}
	}
	return Plugin_Handled;
}
//Rocket fired
public OnEntityCreated(entity,const String:classname[])
{
	if (IsValidEntity(entity))
	{
		if (StrContains(classname,"tf_projectile",false)!=-1) //Hooks all the projectiles
		{
			if (logs)
			{
				LogAction(-1,-1,"Hookin' a %s id %i; type = %i",classname,entity,GetConVarInt(sm_stop_hook))
			}
			if (GetConVarInt(sm_stop_hook)==2)
			{
				SDKHook(entity,SDKHook_ThinkPost,Ent_Created)
			}
			else
			{
				SDKHook(entity,SDKHook_SpawnPost,Ent_Created)
			}
		}
	}
}
//projectile hit
public OnEntityDestroyed(entity)
{
	if (IsValidEntity(entity))
	{
		new String:classname[32]
		new owner = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity")
		
		GetEntPropString(entity,Prop_Data,"m_iClassname",classname,sizeof(classname)) //Have to get classname since EntityDestroyed doesn't give me one :<
		if (StrContains(classname,"tf_projectile",false)!=-1)
		{
			if (logs)
			{
				LogAction(-1,-1,"Un-Hookin' a %s id %i",classname,entity)
			}
			if (IsAClient(owner)&&Effect[owner])
			{
				new Float:ori[3]
				new String:Path[PLATFORM_MAX_PATH]
				new Handle:Classes=INVALID_HANDLE;
				new String:Val[128]
				new String:info[64]
				
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", ori);
				
				BuildPath(Path_SM,Path,sizeof(Path),"configs/Valid spawn classes.txt")
				Classes=CreateKeyValues("Classes")
				FileToKeyValues(Classes,Path)
				KvJumpToKey(Classes,"Saved Classes")
				
				if (KvGotoFirstSubKey(Classes,false))
				{
					do //Running though everything in Saved Classes again; spawning everything that had - ON tag
					{
						KvGetString(Classes,NULL_STRING,Val,sizeof(Val),"nil")
						if (StrEqual(Val,"nil"))
						{
							break;
						}
						KvGetSectionName(Classes,info,sizeof(info))
						if (StrContains(info,"ON")!=-1)
						{
							if (logs) LogAction(-1,-1,"Enabling %s",Val)
							new boom=CreateEntityByName(Val)
							if (IsValidEntity(boom))
							{
								TeleportEntity(boom,ori,NULL_VECTOR,NULL_VECTOR)
								DispatchSpawn(boom)
								SetEntPropEnt(boom,Prop_Send,"m_hOwnerEntity",0) //Very important to set owner to world here; so that if tf_projectile was spawned it doesn't create an endless loop of pain and misery
							}
						}
					}
					while (KvGotoNextKey(Classes,false))
					CloseHandle(Classes)
				}
				else //If there was nothing in the file then create explosion by default
				{
					new boom=CreateEntityByName("tank_destruction")
					ori[2] -= 10.0
					if (IsValidEntity(boom))
					{
						TeleportEntity(boom,ori,NULL_VECTOR,NULL_VECTOR)
						DispatchSpawn(boom)
						SetEntPropEnt(boom,Prop_Send,"m_hOwnerEntity",0)
					}
				}
			}
			if (GetConVarInt(sm_stop_hook)==2)
			{
				SDKUnhook(entity,SDKHook_ThinkPost,Ent_Created)
			}
			else
			{
				SDKUnhook(entity,SDKHook_SpawnPost,Ent_Created)
			}
		}
	}
}
//projectile spawned
public Ent_Created(entity)
{
	new owner = GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity")
	if (IsAClient(owner)&&InUse[owner]&&Valid(owner,entity))
	{
		for (new i = 0; i<GetConVarInt(sm_stop_max_projectiles);i++)
		{
			if (GetArrayCell(Projectiles,owner,i)==0)
			{
				if (IsValidEntity(GetArrayCell(Projectiles,owner,i)))
				{
					if (logs)
					{
						LogAction(-1,-1,"Saved projectile's id %i @ pos N%i",entity,i)
					}
					SetArrayCell(Projectiles,owner,entity,i)
					break;
				}
				else
				{
					if (logs)
					{
						LogAction(-1,-1,"Removed projectile's id %i @ pos N%i",entity,i)
					}
					SetArrayCell(Projectiles,owner,0,i)
				}
			}
		}
		if (logs)
		{
			LogAction(-1,-1,"projectile Spawned; owner = %i",owner)
		}
		CreateTimer(0.001,Timer_Stop,INVALID_HANDLE,TIMER_FLAG_NO_MAPCHANGE) //Since SpawnPost hook fires this too early I must use timer
	}
}
//Stop teh rocket
public Action:Timer_Stop(Handle:timer)
{
	for (new i =1;i<MaxClients;i++)
	{
		if (IsAClient(i)&&InUse[i])
		{
			for (new a=0;a<GetConVarInt(sm_stop_max_projectiles);a++)
			{
				if (GetArrayCell(Projectiles,i,a)!=0)
				{
					if (IsValidEntity(GetArrayCell(Projectiles,i,a))) //Projectile might have died, so must check
					{
						if (logs)
						{
							LogAction(-1,-1,"Got projectile's id : %i;saved at %i",GetArrayCell(Projectiles,i,a),a)
						}
						TeleportEntity(GetArrayCell(Projectiles,i,a),NULL_VECTOR,NULL_VECTOR, Float:{0.0,0.0,0.0}) //Teleporting entity to the same spot, keeping it's angles but setting speed to 0
						SetEntityMoveType(GetArrayCell(Projectiles,i,a),MOVETYPE_FLY) //This is needed in case projectile is not a rocket
					}
					else
					{
						if (logs)
						{
							LogAction(-1,-1,"Removed projectile's id : %i from %i",GetArrayCell(Projectiles,i,a),a)
						}
						SetArrayCell(Projectiles,i,0,a)
					}
				}
			}
		}
	}
}
//Onplayer disconnect
public OnClientDisconnect(client)
{
	if (InUse[client]) //If client was using stop projectiles
	{
		Release(client)
	}
	InUse[client]=false
	Effect[client]=false
}
//OnPlayerMouse2
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (InUse[client])
	{
		if (((buttons & IN_ATTACK2) == IN_ATTACK2))
		{
			Release(client)
		}
	}
	return Plugin_Continue;
}
////Custom funcs
//Release the Kraken
Release(client,max=0) //0 is needed so that when max_projectiles cvar is changed we can still use old value to evade out of bounds error
{
	if (IsAClient(client))
	{
		if (max==0)
		{
			max=GetConVarInt(sm_stop_max_projectiles)
		}
		for (new i = 0; i<max; i++)
		{
			new entity = GetArrayCell(Projectiles,client,i)
			if (IsValidEntity(entity)&&entity!=0&&!IsAClient(entity)) //If it is a valid entity, not a player or world
			{
				new Float:buf[3]
				new Float:ang[3]
				new Float:vel[3]
				new String:classname[64]
				
				GetEntPropString(entity,Prop_Data,"m_iClassname",classname,sizeof(classname))
				GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", ang);
				GetAngleVectors(ang,buf,NULL_VECTOR,NULL_VECTOR)
				
				for (new a=0;a<3;a++)
				{
					vel[a]=buf[a]*GetConVarFloat(sm_stop_speed)
				}
				
				TeleportEntity(GetArrayCell(Projectiles,client,i),NULL_VECTOR,ang, vel)
				SetArrayCell(Projectiles,client,0,i)
			}
			else
			{
				SetArrayCell(Projectiles,client,0,i)
			}
		}
	}
}
//Check if a valid player
IsAClient(index)
{
	if (1<=index<=MaxClients&&IsClientInGame(index))
	{
		return true;
	}
	else
	{
		return false;
	}
}
//Check if valid entry for array
//Needed because for some reason hook is fired twice
//It also cleans array of dead projectiles as a nice bonus C:
Valid(client,entity)
{
	new bool:valid=true
	for (new i=0;i<GetConVarInt(sm_stop_max_projectiles);i++)
	{
		if (GetArrayCell(Projectiles,client,i)==entity)
		{
			 valid=false
		}
		if (!IsValidEntity(GetArrayCell(Projectiles,client,i)))
		{
			SetArrayCell(Projectiles,client,0,i)
		}
	}
	return valid
}