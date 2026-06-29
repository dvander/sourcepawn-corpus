#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>
#include <smlib>
#include <morecolors>

#undef REQUIRE_PLUGIN


public Plugin:myinfo = 
{
	name = "Glove's Menu", 
	author = "AuTok1NGz", 
	description = "Change Your Glove", 
	version = "1.0.0", 
	url = "www.eylonap.xyz"
}


/***********************
 *                     *
 *   Global variables  *
 *                     *
 ***********************/


void download()
{
	// Teams : C9, IMMORTALS, Dignitas, EnvyUs, Epsilon, Faze, fnatic, G2, Gambit, godsent, HR, iBP, Liquid, MOUZ, NiP, NaVi, TSM, virtus, SK-GAMING, team-x
	//Cloud9//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/cloud_9/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/cloud_9/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_cloud_9.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_cloud_9.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_cloud_9.vvd");
	
	//Immortals
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/immortalis/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/immortalis/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_immortalis.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_immortalis.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_immortalis.vvd");
	
	//Dignitas//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/dignitas/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/dignitas/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_dignitas.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_dignitas.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_dignitas.vvd");
	
	//EnvyUs//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/envyus/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/envyus/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_envyus.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_envyus.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_envyus.vvd");
	
	//Epsilon//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/epsilon/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/epsilon/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_epsilon.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_epsilon.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_epsilon.vvd");
	
	//Faze//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/faze/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/faze/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_faze.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_faze.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_faze.vvd");
	
	//fnatic//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/fnatic/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/fnatic/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_fnatic.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_fnatic.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_fnatic.vvd");
	
	//G2//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/g2/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/g2/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_g2.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_g2.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_g2.vvd");
	
	//Gambit//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/gambit/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/gambit/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_gambit.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_gambit.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_gambit.vvd");
	
	//GodSent//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/godsent/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/godsent/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_godsent.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_godsent.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_godsent.vvd");
	
	//HellRairsers//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/hell_raisers/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/hell_raisers/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_hell_raisers.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_hell_raisers.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_hell_raisers.vvd");
	
	//iBP//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/ibp/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/ibp/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_ibp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_ibp.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_ibp.vvd");
	
	//Liquid//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/liquid/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/liquid/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_liquid.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_liquid.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_liquid.vvd");
	
	
	//mouseSports//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/mousesports/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/mousesports/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_mousesports.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_mousesports.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_mousesports.vvd");
	
	//NiP//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/n.i.p/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/n.i.p/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_n.i.p.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_n.i.p.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_n.i.p.vvd");
	
	//Na'Vi//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/navi/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/navi/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_navi.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_navi.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_navi.vvd");

	//TSM//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/tsm/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/tsm/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_tsm.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_tsm.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_tsm.vvd");
	
	//virtus//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/virtus_pro/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/virtus_pro/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_virtus_pro.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_virtus_pro.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_virtus_pro.vvd");
	
	
	//SK-Gaming//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/sk_gaming/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/sk_gaming/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_sk_gaming.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_sk_gaming.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_sk_gaming.vvd");
	
	//Team-X//
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/team_x/ct_base_glove.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/arms/eminem/team_x/ct_base_glove_color.vtf");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_team_x.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_team_x.mdl");
	AddFileToDownloadsTable("models/weapons/eminem/ct_arms_idf_team_x.vvd");

}


void Precache()
{
	PrecacheModel("models/weapons/eminem/ct_arms_idf_virtus_pro.mdl"); // virtus glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_cloud_9.mdl"); // cloud9 glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_immortalis.mdl"); // immortals
	PrecacheModel("models/weapons/eminem/ct_arms_idf_envyus.mdl"); // EnvyUs glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_epsilon.mdl"); // epsilon glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_faze.mdl"); // faze glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_dignitas.mdl"); // dignitas glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_fnatic.mdl"); // fnatic glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_g2.mdl"); // g2 glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_gambit.mdl"); // gambit glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_godsent.mdl"); // godsent glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_hell_raisers.mdl"); // hell raisers glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_ibp.mdl"); // iBuyPower glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_liquid.mdl"); // Liquid glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_mousesports.mdl"); // Mouz Glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_n.i.p.mdl"); // NiP glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_navi.mdl"); // NaVi glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_tsm.mdl"); // TSM Glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_sk_gaming.mdl"); // SK Gaming Glove
	PrecacheModel("models/weapons/eminem/ct_arms_idf_team_x.mdl"); // Team-X Glove
}
bool virtus[33] = false;
bool cloud9[33] = false;
bool immortals[33] = false;
bool EnvyUs[33] = false;
bool epsilon[33] = false;
bool faze[33] = false;
bool dignitas[33] = false;
bool fnatic[33] = false;
bool g2[33] = false;
bool gambit[33] = false;
bool godsent[33] = false;
bool hellraisers[33] = false;
bool iBuyPower[33] = false;
bool Liquid[33] = false;
bool Mouz[33] = false;
bool NiP[33] = false;
bool NaVi[33] = false;
bool TSM[33] = false;
bool SK[33] = false;
bool TeamX[33] = false;


public void OnPluginStart()
{
	/** Hook **/
	HookEvent("player_spawn", ps);
	RegConsoleCmd("sm_gloves", glovemenu);
}

public void OnMapStart()
{
	/** Precache and Models **/
	download();
	Precache();
}

public Action:glovemenu(client, args)
{
	glovesmenu(client);
}

void glovesmenu(client)
{
		Menu newmenu = new Menu(glovesmenu_back);
		newmenu.SetTitle("Wybierz Rekawiczki");
		newmenu.AddItem("Defualt", "Defualt");
		newmenu.AddItem("virtus"), "VirtusPro");
		newmenu.AddItem("cloud9", "Cloud-9");
		newmenu.AddItem("immortals", "Immortals");
		newmenu.AddItem("EnvyUs", "EnvyUs");
		newmenu.AddItem("epsilon", "Epsilon");
		newmenu.AddItem("faze", "Faze");
		newmenu.AddItem("dignitas", "Dignitas");
		newmenu.AddItem("fnatic", "Fnatic");
		newmenu.AddItem("g2", "G2");
		newmenu.AddItem("gambit", "Gambit");
		newmenu.AddItem("godsent", "Godsent");
		newmenu.AddItem("hellraisers", "HellRaisers");
		newmenu.AddItem("iBuyPower", "iBuyPower");
		newmenu.AddItem("Liquid", "Liquid");
		newmenu.AddItem("Mouz", "Mousesports");
		newmenu.AddItem("NiP", "NiP");
		newmenu.AddItem("NaVi", "NaVi");
		newmenu.AddItem("TSM", "TSM");
		newmenu.AddItem("SK", "SK Gaming");
		newmenu.AddItem("TeamX", "TeamX");
		newmenu.ExitButton = true;
		newmenu.Display(client, MENU_TIME_FOREVER);
}

public int glovesmenu_back(Menu newmenu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char iteam[32];
		newmenu.GetItem(param2, iteam, sizeof(iteam));
		if(StrEqual(iteam, "Defualt"))
		{
			cloud9[param1] = false;
			virtus[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;	
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "virtus"))
		{
		    virtus[param1] = true;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "cloud9"))
		{
		    virtus[param1] = false;
			cloud9[param1] = true;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "immortals"))
		{
		    virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = true;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;	
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "EnvyUs"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = true;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "epsilon"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = true;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;		
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "faze"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = true;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "dignitas"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = true;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "fnatic"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = true;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "g2"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = true;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}	
		if(StrEqual(iteam, "gambit"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = true;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "godsent"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = true;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "hellraisers"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = true;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "iBuyPower"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = true;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "Liquid"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = true;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "Mouz"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = true;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "NiP"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = true;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "NaVi"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = true;
			TSM[param1] = false;			
			SK[param1] = false;
			TeamX[param1] = false;
		}		
		if(StrEqual(iteam, "TSM"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = true;			
			SK[param1] = false;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "SK"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;			
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = true;
			TeamX[param1] = false;
		}
		if(StrEqual(iteam, "TeamX"))
		{
			virtus[param1] = false;
			cloud9[param1] = false;
			immortals[param1] = false;
			EnvyUs[param1] = false;
			epsilon[param1] = false;
			faze[param1] = false;
			dignitas[param1] = false;
			fnatic[param1] = false;
			g2[param1] = false;
			gambit[param1] = false;
			godsent[param1] = false;
			hellraisers[param1] = false;
			iBuyPower[param1] = false;
			Liquid[param1] = false;		
			Mouz[param1] = false;
			NiP[param1] = false;
			NaVi[param1] = false;
			TSM[param1] = false;		
			SK[param1] = false;
			TeamX[param1] = true;
		}
		
		glovesmenu(param1);
		
		SetGloves(param1);
		new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");			
		new Handle:h=CreateDataPack();
		WritePackCell(h, param1);
		WritePackCell(h, weapon);		
		CreateTimer(0.1 , UpdateWeapons, h, TIMER_FLAG_NO_MAPCHANGE);
		RemovePlayerItem(param1, weapon);
		
		PrintToChat(param1, " \x04[Rekawiczki] \x07Wybrales \x02%s \x07rekawiczki", iteam);
	}
}
public Action:ps(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);	
	
	SetGloves(client);
}

public void SetGloves(client)
{
    if(virtus[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_virtus_pro.mdl");
	
	if(cloud9[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_cloud_9.mdl");
	
	if(immortals[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_immortalis.mdl");
	
	if(EnvyUs[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_envyus.mdl");
	
	if(faze[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_faze.mdl");
	
	if(dignitas[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_dignitas.mdl");
	
	if(epsilon[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_epsilon.mdl");
	
	if(fnatic[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_fnatic.mdl");
	
	if(g2[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_g2.mdl");
	
	if(gambit[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_gambit.mdl");
	
	if(godsent[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_godsent.mdl");
	
	if(hellraisers[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_hell_raisers.mdl");
	
	if(iBuyPower[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_ibp.mdl");
	
	if(Liquid[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_liquid.mdl");
	
	if(Mouz[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_mousesports.mdl");
	
	if(NiP[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_n.i.p.mdl");
	
	if(NaVi[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_navi.mdl");
	
	if(TSM[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_tsm.mdl");
	
	if(SK[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_sk_gaming.mdl");
	
	if(TeamX[client])
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/eminem/ct_arms_idf_team_x.mdl");
}

public IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
}

public Action:UpdateWeapons(Handle:timer, any:h)
{  

	ResetPack(h);
	new userid=ReadPackCell(h);
	new weapon=ReadPackCell(h);
	
	EquipPlayerWeapon(userid, weapon);
}