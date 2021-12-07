#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Be the Chozo",
	author = "svaugrasn",
	description = "Meet the Chozo",
	version = PLUGIN_VERSION,
	url = "http://dl.dropboxusercontent.com/u/7333770/tf2/tool.html"
}

new bool:isChozo[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
	RegConsoleCmd("chozo", BetheChozo);
	RegConsoleCmd("stopchozo", StopChozo);
	AddNormalSoundHook(HookSound);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/misc/chozo/Bonesaw'sReady_1.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Dominated.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Don'tWorry.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/EffYouSeeKayLet'sGo.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/EntireTeamIsBabies.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FiveFk_1.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FiveFk_2.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Fk'Em!.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FkingEngineerWithoutAGun.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FkThem.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FkYeahGetFked.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/FkYeahIGotRapeBannered.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/GetDominated_1.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/GetDominated_2.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/GetFked.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/GetTheFkingPyro.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/GoodJobMedic.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/HereWeGo.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/HisName'sNotFkingChoZoDon'tFkingHealHim.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/I'mDyinHere.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/I'mFkingHungry.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/IGotThisSht.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/IHaveNataska.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/IOnlyHaveOneMedic.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Let'sGo_1.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Let'sGo_2.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Let'sGo_3.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/MedicMedicFkingMedic.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/OhHamburgers.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/PutAFkingDispenserHere.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Rage.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/ReleaseTheRage_2.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/SandwichEatIt.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/Ubercharge.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/UberUberUberUber.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/UnlimitedPower_1.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/UnlimitedPower_2.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/What'sThatSandwichKillThemAll.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/WhatAreYouDoing.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/WhereAreYouRunning.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/YouAllFkingSuck.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/YouMedicsSuck.mp3");
	AddFileToDownloadsTable("sound/misc/chozo/YouNeedMoreFkingChoZo.mp3");

	PrecacheSound("misc/chozo/Bonesaw'sReady_1.mp3");
	PrecacheSound("misc/chozo/Dominated.mp3");
	PrecacheSound("misc/chozo/Don'tWorry.mp3");
	PrecacheSound("misc/chozo/EffYouSeeKayLet'sGo.mp3");
	PrecacheSound("misc/chozo/EntireTeamIsBabies.mp3");
	PrecacheSound("misc/chozo/FiveFk_1.mp3");
	PrecacheSound("misc/chozo/FiveFk_2.mp3");
	PrecacheSound("misc/chozo/Fk'Em!.mp3");
	PrecacheSound("misc/chozo/FkingEngineerWithoutAGun.mp3");
	PrecacheSound("misc/chozo/FkThem.mp3");
	PrecacheSound("misc/chozo/FkYeahGetFked.mp3");
	PrecacheSound("misc/chozo/FkYeahIGotRapeBannered.mp3");
	PrecacheSound("misc/chozo/GetDominated_1.mp3");
	PrecacheSound("misc/chozo/GetDominated_2.mp3");
	PrecacheSound("misc/chozo/GetFked.mp3");
	PrecacheSound("misc/chozo/GetTheFkingPyro.mp3");
	PrecacheSound("misc/chozo/GoodJobMedic.mp3");
	PrecacheSound("misc/chozo/HereWeGo.mp3");
	PrecacheSound("misc/chozo/HisName'sNotFkingChoZoDon'tFkingHealHim.mp3");
	PrecacheSound("misc/chozo/I'mDyinHere.mp3");
	PrecacheSound("misc/chozo/I'mFkingHungry.mp3");
	PrecacheSound("misc/chozo/IGotThisSht.mp3");
	PrecacheSound("misc/chozo/IHaveNataska.mp3");
	PrecacheSound("misc/chozo/IOnlyHaveOneMedic.mp3");
	PrecacheSound("misc/chozo/Let'sGo_1.mp3");
	PrecacheSound("misc/chozo/Let'sGo_2.mp3");
	PrecacheSound("misc/chozo/Let'sGo_3.mp3");
	PrecacheSound("misc/chozo/MedicMedicFkingMedic.mp3");
	PrecacheSound("misc/chozo/OhHamburgers.mp3");
	PrecacheSound("misc/chozo/PutAFkingDispenserHere.mp3");
	PrecacheSound("misc/chozo/Rage.mp3");
	PrecacheSound("misc/chozo/ReleaseTheRage_2.mp3");
	PrecacheSound("misc/chozo/SandwichEatIt.mp3");
	PrecacheSound("misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
	PrecacheSound("misc/chozo/Ubercharge.mp3");
	PrecacheSound("misc/chozo/UberUberUberUber.mp3");
	PrecacheSound("misc/chozo/UnlimitedPower_1.mp3");
	PrecacheSound("misc/chozo/UnlimitedPower_2.mp3");
	PrecacheSound("misc/chozo/What'sThatSandwichKillThemAll.mp3");
	PrecacheSound("misc/chozo/WhatAreYouDoing.mp3");
	PrecacheSound("misc/chozo/WhereAreYouRunning.mp3");
	PrecacheSound("misc/chozo/YouAllFkingSuck.mp3");
	PrecacheSound("misc/chozo/YouMedicsSuck.mp3");
	PrecacheSound("misc/chozo/YouNeedMoreFkingChoZo.mp3");

	LogMessage("BE THE CHOZO IS READY");

}

public Action:BetheChozo(client, args)
{

if (!isChozo[client])
{
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		
		SetHudTextParams(-1.0, 0.65, 10.0, 0, 255, 0, 255);
		ShowHudText(client, -1, "Now you are Chozo.");
		EmitSoundToAll("misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
		new String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("[Be the Chozo]%s became to the Chozo.", name);
		isChozo[client] = true;
	}
	else
	{
		SetHudTextParams(-1.0, 0.65, 10.0, 255, 0, 0, 255);
		ShowHudText(client, -1, "Heavy Only");
	}

}
}

public Action:StopChozo(client, args)
{

if (isChozo[client])
{
	isChozo[client] = false;
	SetHudTextParams(-1.0, 0.65, 10.0, 255, 0, 0, 255);
	ShowHudText(client, -1, "Chozo has been disabled.");
	EmitSoundToClient(client, "misc/chozo/I'mFkingHungry.mp3");
}

}

public Action:HookSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (ent < 1 || ent > MaxClients || channel < 1)
		return Plugin_Continue;
	
	if (isChozo[ent])
	{
		if (TF2_GetPlayerClass(ent) != TFClass_Heavy)
		{
			isChozo[ent] = false;
			SetHudTextParams(-1.0, 0.65, 10.0, 255, 0, 0, 255);
			ShowHudText(ent, -1, "Chozo has been disabled.");
		}

		new rint = GetRandomInt(0,2);

		if(StrContains(sample, "misc/chozo/", false) == -1)
			volume = 0.0;

		if(StrContains(sample, "vo/heavy_activatecharge", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UberUberUberUber.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_autocappedcontrolpoint", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/WhatAreYouDoing.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/WhatAreYouDoing.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_autocappedintelligence", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/IHaveNataska.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_autoonfire", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahIGotRapeBannered.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Fk'Em!.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GetTheFkingPyro.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_battlecry", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Fk'Em!.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cartgoingbackdefense", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cartgoingbackoffense", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cartmovingforwarddefense", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cartmovingforwardoffense", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cartstopitdefense", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_cartstoppedoffense", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_cheers", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Bonesaw'sReady_1.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/HisName'sNotFkingChoZoDon'tFkingHealHim.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_cloakedspy", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_domination", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GetDominated_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GetDominated_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Dominated.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_fairyprincess", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/OhHamburgers.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_fightoncap", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/WhatAreYouDoing.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/WhatAreYouDoing.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_generic01", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_go", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_3.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_goodjob", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Don'tWorry.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_headleft", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_headright", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/WhereAreYouRunning.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_helpme", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/IOnlyHaveOneMedic.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/MedicMedicFkingMedic.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/I'mDyinHere.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_incoming", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_jeers", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Fk'Em!.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_laugherbigsnort", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GetFked.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_laughevil", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Fk'Em!.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_laughhappy", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Bonesaw'sReady_1.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_laugh", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_medic", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/IOnlyHaveOneMedic.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/MedicMedicFkingMedic.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/MedicMedicFkingMedic.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_melee", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Bonesaw'sReady_1.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_moveup", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EffYouSeeKayLet'sGo.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Let'sGo_3.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/HereWeGo.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_mvm_", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Bonesaw'sReady_1.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_need", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/PutAFkingDispenserHere.mp3");
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_negative", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}


		if(StrContains(sample, "vo/heavy_niceshot", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Fk'Em!.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_no", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/EntireTeamIsBabies.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_paincrticialdeath", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouMedicsSuck.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_pain", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Rage.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_positive", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/ReleaseTheRage_2.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_revenge", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/ReleaseTheRage_2.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_sandwichtaunt", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/What'sThatSandwichKillThemAll.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/I'mFkingHungry.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/IGotThisSht.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_scram2012_falling01", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouAllFkingSuck.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_sentryahead", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkingEngineerWithoutAGun.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_sf12_", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_2.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_singing", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouNeedMoreFkingChoZo.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_specialcompleted04", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Ubercharge.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_specialcompleted05", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Ubercharge.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_specialcompleted06", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Ubercharge.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/taunts/heavy_taunts03", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/taunts/heavy_taunts16", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_1.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/taunts/heavy_taunts", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouNeedMoreFkingChoZo.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_specialcompleted", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouNeedMoreFkingChoZo.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_specialcompleted-assistedkill01", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/GoodJobMedic.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_special", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_2.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_thanks", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FkYeahGetFked.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/Bonesaw'sReady_1.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/sandwicheat09", false) != -1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/SandwichEatIt.mp3");
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_yell", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/UnlimitedPower_1.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouNeedMoreFkingChoZo.mp3");
			}
			volume = 1.0;
		}

		if(StrContains(sample, "vo/heavy_yes", false) != -1){
			if(rint == 0){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/That'sTheSoundOfMyFkingGun.mp3");
			}
			if(rint == 1){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/FiveFk_1.mp3");
			}
			if(rint == 2){
			Format(sample, PLATFORM_MAX_PATH, "misc/chozo/YouNeedMoreFkingChoZo.mp3");
			}
			volume = 1.0;
		}

		return Plugin_Changed;

	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (isChozo[client])
	{
		isChozo[client] = false;
		EmitSoundToAll("misc/chozo/I'mFkingHungry.mp3");
	}
}
