#pragma semicolon 1

/*
Known issues: 
Disguised spies don't have replaced lines
Calling someone a spy usuaully uses the wrong class
If Pyro is used for calling someone a spy, it's broken
Pyro in general has a lot of missing voicelines (or mumbles I guess)
Group taunts don't work (where the fuck are they located if not in VO?)
*/

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION "1.0"
#define MAX_RANDOM_ITERATIONS 5

new bool:AdminOverrideDefault = false;
new AdminOverrideModeDefault = 1;
new bool:AdminOverride = false;
new AdminOverrideChoice = 1;

new PlayerModeDefault = 1;
new PlayerChoice[MAXPLAYERS+1]; //0 = Don't randomize, 1 = Randomize, 2 = Duck, 3-11 = Mercs

new Handle:cvarPlayerModeDefault = INVALID_HANDLE;
new Handle:cvarAdminOverrideDefault = INVALID_HANDLE;
new Handle:cvarAdminOverrideModeDefault = INVALID_HANDLE;

public Plugin:myinfo = {
   name = "TF2 Voiceover Randomizer",
   author = "Ankhxy",
   description = "Randomizes mercenary voicelines with a different merc",
   version = PLUGIN_VERSION
}

public OnPluginStart()
{
	PrintToServer("== VO Randomizer Loaded ==");
	AddNormalSoundHook(NormalSHook:Hook_EntitySound);
	
	RegConsoleCmd("vor", MainMenu);
	RegAdminCmd("vor_admin", AdminOverrideMenu, ADMFLAG_GENERIC, "Voiceover Randomizer Admin Menu");
	
	cvarPlayerModeDefault = CreateConVar("vor_PlayerModeDefault", "1", 
	"What VOR mode a player will default to when joining the server. 0 = Don't randomize, 1 = Randomize, 2 = Duck, 3-11 = Mercs.",
	FCVAR_NONE, true, 0.0, true, 11.0);
	
	cvarAdminOverrideModeDefault = CreateConVar("vor_adminoverridemodedefault", "1",
	"What VOR mode is the default in Admin Override. 0 = Don't randomize, 1 = Randomize, 2 = Duck, 3-11 = Mercs.",
	FCVAR_NONE, true, 0.0, true, 11.0);
	
	cvarAdminOverrideDefault = CreateConVar("vor_adminoverridedefault", "0",
	"Whether Admin Override is on by default. 0 = No, 1 = Yes",
	FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookConVarChange(cvarPlayerModeDefault, CvarChange);
	HookConVarChange(cvarAdminOverrideModeDefault, CvarChange);
	HookConVarChange(cvarAdminOverrideDefault, CvarChange);
	
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarPlayerModeDefault)
		PlayerModeDefault = StringToInt(newValue);
	if (convar == cvarAdminOverrideModeDefault)
		AdminOverrideModeDefault = StringToInt(newValue);
	if (convar == cvarAdminOverrideDefault)
		AdminOverrideDefault = bool:StringToInt(newValue);
}

public OnClientPutInServer(client)
{
	PlayerChoice[client] = PlayerModeDefault;
}

public OnMapStart()
{
}

public OnConfigsExecuted()
{
	PrecacheSound("ambient/bumper_car_quack1.wav", true);
	PrecacheSound("ambient/bumper_car_quack2.wav", true);
	PrecacheSound("ambient/bumper_car_quack3.wav", true);
	PrecacheSound("ambient/bumper_car_quack4.wav", true);
	PrecacheSound("ambient/bumper_car_quack5.wav", true);
	PrecacheSound("ambient/bumper_car_quack9.wav", true);
	PrecacheSound("ambient/bumper_car_quack11.wav", true);
	
	PlayerModeDefault = GetConVarInt(cvarPlayerModeDefault);
	AdminOverrideChoice = bool:GetConVarInt(cvarAdminOverrideModeDefault);
	AdminOverride = bool:GetConVarInt(cvarAdminOverrideDefault);
}


public Action Hook_EntitySound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],
							   int &client, int &channel, float &volume, int &level, int &pitch, 
							   int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{	
	new TFClassType:SoundClass = TFClass_Unknown;
	
	decl String:OriginalSound[PLATFORM_MAX_PATH];
	OriginalSound[0] = '\0';
	strcopy(OriginalSound, sizeof(OriginalSound), sample);
	
	if(StrContains(sample, "vo/", false) != -1)
	{
		if(StrContains(sample, "vo/scout", false) != -1)
			SoundClass = TFClass_Scout;
		else if (StrContains(sample, "vo/sniper", false) != -1)
			SoundClass = TFClass_Sniper;
		else if (StrContains(sample, "vo/soldier", false) != -1)
			SoundClass = TFClass_Soldier;
		else if (StrContains(sample, "vo/demoman", false) != -1)
			SoundClass = TFClass_DemoMan;
		else if (StrContains(sample, "vo/medic", false) != -1)
			SoundClass = TFClass_Medic;
		else if (StrContains(sample, "vo/heavy", false) != -1)
			SoundClass = TFClass_Heavy;
		else if (StrContains(sample, "vo/pyro", false) != -1)
			SoundClass = TFClass_Pyro;
		else if (StrContains(sample, "vo/spy", false) != -1)
			SoundClass = TFClass_Spy;
		else if (StrContains(sample, "vo/engineer", false) != -1)
			SoundClass = TFClass_Engineer;
	}
	else
	{
		//PrintToChatAll("VO_DEBUG - Sound did not contain vo/");
	}
	
	if(SoundClass != TFClass_Unknown)
	{
		new TFClassType:NewClass = TFClass_Unknown;
		
		if(AdminOverride && AdminOverrideChoice != 1)
		{
			if(AdminOverrideChoice > 2)
				NewClass = IntToClass(AdminOverrideChoice);
			else if (AdminOverrideChoice == 2)
			{
				switch(GetRandomInt(1,7))
				{
					case 1: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack1.wav");
					case 2: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack2.wav");
					case 3: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack3.wav");
					case 4: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack4.wav");
					case 5: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack5.wav");
					case 6: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack9.wav");
					case 7: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack11.wav");
				}

				EmitSound(clients, numClients, sample, client, channel, SNDLEVEL_NORMAL, flags, volume, pitch, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			}
			else if (AdminOverrideChoice == 0)
			{
				return Plugin_Continue;
			}
		}
		
		if((AdminOverride && AdminOverrideChoice == 1) || !AdminOverride || (AdminOverride && AdminOverrideChoice > 2))
		{
			if(PlayerChoice[client] == 0)
			{
				return Plugin_Continue;
			}
			else if(PlayerChoice[client] > 2 && !(AdminOverride && AdminOverrideChoice > 2))
			{
				NewClass = IntToClass(PlayerChoice[client]);
			}
			else if(PlayerChoice[client] == 1 && !(AdminOverride && AdminOverrideChoice > 2))
			{
				if(TF2_GetPlayerClass(client) == SoundClass)
				{
					for(new i = 0; i<=MAX_RANDOM_ITERATIONS; i++)
					{
						NewClass = GetRandomClass();
						
						if(SoundClass != NewClass)
							break;
					}
				}
			}
					
			ReplaceString(sample, sizeof(sample), ClassToString(TF2_GetPlayerClass(client)), ClassToString(NewClass));
			StrToLower(sample, sample, sizeof(sample));
			//PrecacheSound(sample);
			ReplaceString(sample, sizeof(sample), "vo/", "sound/vo/");
			//PrintToChatAll("VO_DEBUG - New sound is: %s", sample);
			
			new bool:FoundReplacement = false;
			
			if(FileExists(sample, true))
			{
				FoundReplacement = true;
				ReplaceString(sample, sizeof(sample), "sound/", "");
				EmitSound(clients, numClients, sample, client, channel, SNDLEVEL_NORMAL, flags, volume, pitch, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				//PrintToChatAll("VO_DEBUG - Precache state: %i", IsSoundPrecached(sample));
				
				return Plugin_Stop;
			}
			else
			{
				//PrintToChatAll("VO DEBUG - Looking for a replacement string...");
				new String:NumStr[5], String:NumStr2[5], String:NumStr3[5], String:iBuffer[5];
				NumStr2[0] = 'x';
				
				for(new i = 50; i > 1; i--)
				{
					IntToString(i, iBuffer, sizeof(iBuffer)); //To store the current iteration as a string
					//PrintToChatAll("VO DEBUG - Iteration: %s", iBuffer);
					
					if(i < 10)
						Format(NumStr, sizeof(NumStr), "0%i", i); //Adding a 0 to single digit numbers i.e., 1 into 01
					else 
						strcopy(NumStr, sizeof(NumStr), iBuffer); //Otherwise, just use it
						
					if(StrContains(sample, NumStr, false) != -1) //Looking for the current number this sample has so it can be replaced
					{
						strcopy(NumStr2, sizeof(NumStr2), NumStr); //Storing it for later
						//PrintToChatAll("VO DEBUG - Found the number in the sample: %s", sample);
					}
					
					if(NumStr2[0] != 'x') //Used so we don't try and use an empty string
					{
						ReplaceString(sample, sizeof(sample), NumStr2, NumStr); //Replacing the number in the sample with the current i
						//PrintToChatAll("VO DEBUG - Replacing the number in the sample");
					}
					
					if(StrContains(sample, "sound/", false) == -1) //Adding sound/ to the path so it can be checked with fileexists
						ReplaceString(sample, sizeof(sample), "vo/", "sound/vo/");
					
					if(FileExists(sample, true)) //We've now found the next available sound for this
					{
						FoundReplacement = true;
						//PrintToChatAll("VO DEBUG - Found a replacement string: %s", sample);
						new Rand = GetRandomInt(1, i); //Now we'll use a random one between the one we've found and 1
						
						if(Rand < 10)
							Format(NumStr3, sizeof(NumStr3), "0%i", Rand); //Just what we did before
						else 
							strcopy(NumStr3, sizeof(NumStr3), iBuffer); //^
							
						ReplaceString(sample, sizeof(sample), NumStr, NumStr3); //Placing our new generated number back into the string
						ReplaceString(sample, sizeof(sample), "sound/vo/", "vo/"); //Taking away "sound/" from the path as it'll break the search
						
						EmitSound(clients, numClients, sample, client, channel, SNDLEVEL_NORMAL, flags, volume, pitch, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
						
						return Plugin_Stop; //Stop the original sound from playing
					}
					else
						ReplaceString(sample, sizeof(sample), NumStr, NumStr2); //Placing the samples original number back into it
				}
			}
			
			if(!FoundReplacement || PlayerChoice[client] == 2)
			{
				switch(GetRandomInt(1,7))
				{
					case 1: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack1.wav");
					case 2: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack2.wav");
					case 3: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack3.wav");
					case 4: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack4.wav");
					case 5: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack5.wav");
					case 6: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack9.wav");
					case 7: strcopy(sample, sizeof(sample), "ambient/bumper_car_quack11.wav");
				}
			}
		}
		
		EmitSound(clients, numClients, sample, client, channel, SNDLEVEL_NORMAL, flags, volume, pitch, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

		LogError("VO DEBUG - Failed to find a replacement sound, was: %s. Target class was %s", OriginalSound, ClassToString(NewClass));
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

TFClassType:GetRandomClass()
{
	//Returns a random class surprisingly!
	new TFClassType:Class = TFClass_Unknown;
	
	switch(GetRandomInt(1,9))
	{
		case 1: Class = TFClass_Scout;
		case 2: Class = TFClass_Sniper;
		case 3: Class = TFClass_Soldier;
		case 4: Class = TFClass_DemoMan;
		case 5: Class = TFClass_Medic;
		case 6: Class = TFClass_Heavy;
		case 7: Class = TFClass_Pyro;
		case 8: Class = TFClass_Spy;
		case 9: Class = TFClass_Engineer;
	}
	
	return Class;
}

String:ClassToString(TFClassType:Class)
{
	//Given a Class, will convert it into a string
	//Apparently functions can't return strings in Pawn, well I fucking did
	decl String:ClassString[10];
	ClassString[0] = '\0';
		
	switch(Class)
	{
		case TFClass_Scout: strcopy(ClassString, 10, "scout");
		case TFClass_Sniper: strcopy(ClassString, 10, "sniper");
		case TFClass_Soldier: strcopy(ClassString, 10, "soldier");
		case TFClass_DemoMan: strcopy(ClassString, 10, "demoman");
		case TFClass_Medic: strcopy(ClassString, 10, "medic");
		case TFClass_Heavy: strcopy(ClassString, 10, "heavy");
		case TFClass_Pyro: strcopy(ClassString, 10, "pyro");
		case TFClass_Spy: strcopy(ClassString, 10, "spy");
		case TFClass_Engineer: strcopy(ClassString, 10, "engineer");
	}
	
	return ClassString;
}

TFClassType:IntToClass(int InputInt)
{
	new TFClassType:Class = TFClass_Unknown;
	
	switch (InputInt)
	{
		case 3: Class = TFClass_Scout;
		case 4: Class = TFClass_Sniper;
		case 5: Class = TFClass_Soldier;
		case 6: Class = TFClass_DemoMan;
		case 7: Class = TFClass_Medic;
		case 8: Class = TFClass_Heavy;
		case 9: Class = TFClass_Pyro;
		case 10: Class = TFClass_Spy;
		case 11: Class = TFClass_Engineer;
	}
	
	return Class;
}

void ChoiceToString(String:buffer[], bufsize, int Choice)
{
	switch(Choice)
	{
		case 0: strcopy(buffer, bufsize, "Not randomized");
		case 1: strcopy(buffer, bufsize, "Randomized");
		case 2: strcopy(buffer, bufsize, "Duck");
		case 3: strcopy(buffer, bufsize, "Scout");
		case 4: strcopy(buffer, bufsize, "Sniper");
		case 5: strcopy(buffer, bufsize, "Soldier");
		case 6: strcopy(buffer, bufsize, "Demo");
		case 7: strcopy(buffer, bufsize, "Medic");
		case 8: strcopy(buffer, bufsize, "Heavy");
		case 9: strcopy(buffer, bufsize, "Pyro");
		case 10: strcopy(buffer, bufsize, "Spy");
		case 11: strcopy(buffer, bufsize, "Engineer");
	}
}

public MainMenuHandler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		if(selection == 1)
		{
			ModeMenu1(client, 0);
		}
		else if(selection == 4)
		{
			FAQMenu(client, 0);
		}
		else if(selection == 5)
		{
			AnkhxyMenu(client, 0);
		}
	}
}

public Action:MainMenu(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Voiceover Randomizer Menu");
	
	decl String:buffer[20], String:buffer2[64];
	buffer[0] = '\0';
	buffer2[0] = '\0';
	ChoiceToString(buffer, sizeof(buffer), PlayerChoice[client]);
	Format(buffer2, sizeof(buffer2), "Your current mode: %s", buffer);
	
	panel.DrawItem("Mode options ->");
	panel.DrawItem(buffer2);
	if(AdminOverride)
		panel.DrawItem("Admin Override is ENABLED");
	else
		panel.DrawItem("Admin Override is DISABLED");
	panel.DrawItem("FAQ and known issues ->");
	panel.DrawItem("Made by Ankhxy");
	
	panel.Send(client, MainMenuHandler, 30);
	
	delete panel;
 
	return Plugin_Handled;
}

public ModeMenu1Handler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		if(selection < 4)
			PlayerChoice[client] = selection-1;
		else if(selection == 4)
			ModeMenu2(client, 0);
		else if(selection == 5)
			MainMenu(client, 0);
	}
}

public Action:ModeMenu1(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Mode options page 1");
	
	panel.DrawItem("Don't randomize me");
	panel.DrawItem("Randomize me");
	panel.DrawItem("Duck");
	panel.DrawItem("Class specific ->");
	panel.DrawItem("<- Go back");
	
	panel.Send(client, ModeMenu1Handler, 20);
	
	delete panel;
	
	return Plugin_Handled;
}

public ModeMenu2Handler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		switch(selection)
		{
		case 1: PlayerChoice[client] = 3;
		case 2: PlayerChoice[client] = 5;
		case 3: PlayerChoice[client] = 9;
		case 4: PlayerChoice[client] = 6;
		case 5: PlayerChoice[client] = 8;
		case 6: PlayerChoice[client] = 11;
		case 7: PlayerChoice[client] = 7;
		case 8: PlayerChoice[client] = 4;
		case 9: PlayerChoice[client] = 10;
		case 10: ModeMenu1(client, 0);
		}
	}
}

public Action:ModeMenu2(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Mode options page 2");
	panel.DrawItem("Scout");
	panel.DrawItem("Soldier");
	panel.DrawItem("Pyro");
	panel.DrawItem("Demo");
	panel.DrawItem("Heavy");
	panel.DrawItem("Engineer");
	panel.DrawItem("Medic");
	panel.DrawItem("Sniper");
	panel.DrawItem("Spy");
	panel.DrawItem("<- Go back");
	panel.Send(client, ModeMenu2Handler, 20);
	
	delete panel;

	return Plugin_Handled;
}

public FAQMenuHandler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select && selection == 9)
		MainMenu(client, 0);
}

public Action:FAQMenu(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("FAQ and known issues");
	panel.DrawItem("- FAQ -");
	panel.DrawItem("Quacks? If the mod fails to find a replacement, a quack is used");
	panel.DrawItem("My mode isn't working? Admins can override everyones choice");
	panel.DrawItem("- KNOWN ISSUES -");
	//panel.DrawItem("Disguised spies can only quack");
	panel.DrawItem("Claiming someone is a spy usually calls them the wrong class");
	panel.DrawItem("Group taunts don't have replacement lines");
	panel.DrawItem("Pyro voicelines usually don't work");
	panel.DrawItem("Everyone hears different voicelines (Valve issue?)");
	panel.DrawItem("<- Go back");
	panel.Send(client, FAQMenuHandler, 40);
	
	delete panel;
	
	return Plugin_Handled;
}

public AnkhxyMenuHandler(Menu menu, MenuAction action, client, selection)
{
}

public Action:AnkhxyMenu(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Goat Butt");
	panel.DrawItem(":3");
	panel.Send(client, AnkhxyMenuHandler, 10);
	
	delete panel;
 
	return Plugin_Handled;
}

public AdminMenuHandler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		if(selection == 2)
		{
			if(AdminOverride)
			{
				AdminOverride = false;
				PrintCenterTextAll("VOR - Admin Override has been DISABLED");
			}
			else
			{
				AdminOverride = true;
				PrintCenterTextAll("VOR - Admin Override has been ENABLED");
				AdminModeMenu1(client, 0);
			}
		}
		if(selection == 4)
		{
			AdminModeMenu1(client, 0);
		}
	}
}

public Action:AdminOverrideMenu(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Voiceover Randomizer Admin Menu");
	
	decl String:buffer[20], String:buffer2[64];
	buffer[0] = '\0';
	buffer2[0] = '\0';
	ChoiceToString(buffer, sizeof(buffer), AdminOverrideChoice);
	Format(buffer2, sizeof(buffer2), "Admin Override mode: %s", buffer);
	
	if(AdminOverride)
		panel.DrawItem("Admin Override is ENABLED");
	else
		panel.DrawItem("Admin Override is DISABLED");
	panel.DrawItem("Toggle Admin Override ->");
	panel.DrawItem(buffer2);
	panel.DrawItem("Change Admin Override Mode ->");
	panel.Send(client, AdminMenuHandler, 10);
	
	delete panel;
 
	return Plugin_Handled;
}

public AdminModeMenu1Handler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		if(selection < 4)
			AdminOverrideChoice = selection-1;
		else if(selection == 4)
			AdminModeMenu2(client, 0);
		else if(selection == 5)
			AdminOverrideMenu(client, 0);
	}
}

public Action:AdminModeMenu1(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Admin Mode options page 1");
	
	panel.DrawItem("Don't randomize");
	panel.DrawItem("Randomize");
	panel.DrawItem("Duck");
	panel.DrawItem("Class specific ->");
	panel.DrawItem("<- Go back");
	
	panel.Send(client, AdminModeMenu1Handler, 20);
	
	delete panel;
	
	return Plugin_Handled;
}

public AdminModeMenu2Handler(Menu menu, MenuAction action, client, selection)
{
	if(action == MenuAction_Select)
	{
		switch(selection)
		{
		case 1: AdminOverrideChoice = 3;
		case 2: AdminOverrideChoice = 5;
		case 3: AdminOverrideChoice = 9;
		case 4: AdminOverrideChoice = 6;
		case 5: AdminOverrideChoice = 8;
		case 6: AdminOverrideChoice = 11;
		case 7: AdminOverrideChoice = 7;
		case 8: AdminOverrideChoice = 4;
		case 9: AdminOverrideChoice = 10;
		case 10: AdminModeMenu1(client, 0);
		}
	}
}

public AdminAction:AdminModeMenu2(int client, int args)
{
	Panel panel = new Panel();
	panel.SetTitle("Admin Mode options page 2");
	panel.DrawItem("Scout");
	panel.DrawItem("Soldier");
	panel.DrawItem("Pyro");
	panel.DrawItem("Demo");
	panel.DrawItem("Heavy");
	panel.DrawItem("Engineer");
	panel.DrawItem("Medic");
	panel.DrawItem("Sniper");
	panel.DrawItem("Spy");
	panel.DrawItem("<- Go back");
	panel.Send(client, AdminModeMenu2Handler, 20);
	
	delete panel;
	
	return Plugin_Handled;
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

stock StrToLower(const String:str[], String:buffer[], bufsize) 
{
    new n=0, x=0;
    while (str[n] != '\0' && x < (bufsize-1)) { // Make sure we are inside bounds

        new chara = str[n++]; // Caching

        if (IsCharUpper(chara)) { // Am I big ?
            chara = CharToLower(chara); // Big becomes low
        }

        buffer[x++] = chara; // Write into our new string
    }

    buffer[x++] = '\0'; // Finalize with the end ( = always 0 for strings)

    return x; // return number of bytes written for later proove
}  