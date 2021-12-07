#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "soundboard",
    author = "",
    description = "",
    version = "0.0.1",
    url = "none"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sounds.phrases");
        RegAdminCmd("sm_chocolate", Cmd_chocolate, ADMFLAG_VOTE, "Give chocolate to player." );
	RegConsoleCmd("sm_ds", Cmd_ds, "Refuse to disable ds." );
	RegAdminCmd("sm_vodka", Cmd_vodka, ADMFLAG_VOTE, "You Gin" );
	RegAdminCmd("sm_gin", Cmd_gin, ADMFLAG_VOTE, "I Vodka" );
	RegAdminCmd("sm_socks", Cmd_socks, ADMFLAG_VOTE, "socks" );
	RegAdminCmd("sm_cry", Cmd_cry, ADMFLAG_VOTE, "cry" );
	RegAdminCmd("sm_hax", Cmd_hax, ADMFLAG_VOTE, "HAX" );
	RegAdminCmd("sm_parade", Cmd_parade, ADMFLAG_VOTE, "parade" );
	RegAdminCmd("sm_tickle", Cmd_tickle, ADMFLAG_VOTE, "Tickle me" );
	RegAdminCmd("sm_fuckoff", Cmd_fuckoff, ADMFLAG_VOTE, "Ban Hammer" );
	RegAdminCmd("sm_banhammer", Cmd_banhammer, ADMFLAG_VOTE, "Ban Hammer" );
	RegAdminCmd("sm_banhammer2", Cmd_banhammer2, ADMFLAG_VOTE, "Ban Hammer2" );
	RegAdminCmd("sm_save", Cmd_save, ADMFLAG_VOTE, "save" );
	RegAdminCmd("sm_save2", Cmd_save2, ADMFLAG_VOTE, "save2" );
	RegAdminCmd("sm_lasagna", Cmd_lasagna, ADMFLAG_VOTE, "I hate mondays" );
	RegAdminCmd("sm_fart", Cmd_fart, ADMFLAG_VOTE, "Farting aha" );
	RegAdminCmd("sm_pidor", Cmd_pidor, ADMFLAG_VOTE, "pidor" );
	RegAdminCmd("sm_steam", Cmd_steam, ADMFLAG_VOTE, "I love Steam" );
	RegAdminCmd("sm_pee", Cmd_pee, ADMFLAG_VOTE, "Have to pee" );
	RegAdminCmd("sm_sex", Cmd_sex, ADMFLAG_VOTE, "Let's do it" );
	RegAdminCmd("sm_sex2", Cmd_sex2, ADMFLAG_VOTE, "Let's do it" );
	RegAdminCmd("sm_license", Cmd_license, ADMFLAG_VOTE, "license" );
	RegAdminCmd("sm_license2", Cmd_license2, ADMFLAG_VOTE, "license2" );
	RegAdminCmd("sm_bitch", Cmd_bitch, ADMFLAG_VOTE, "bitch" );
	RegAdminCmd("sm_bitch2", Cmd_bitch2, ADMFLAG_VOTE, "bitch2" );
	RegAdminCmd("sm_easy", Cmd_easy, ADMFLAG_VOTE, "easy" );
	RegAdminCmd("sm_orgasm", Cmd_orgasm, ADMFLAG_VOTE, "mmmmh" );
	RegAdminCmd("sm_love", Cmd_love, ADMFLAG_VOTE, "Oh good morning" );
	RegAdminCmd("sm_anal", Cmd_anal, ADMFLAG_VOTE, "Cannot believe" );
	RegAdminCmd("sm_anus", Cmd_anus, ADMFLAG_VOTE, "shit" );
	RegAdminCmd("sm_bad", Cmd_bad, ADMFLAG_VOTE, "bad" );
	RegAdminCmd("sm_sugar", Cmd_sugar, ADMFLAG_VOTE, "sugar" );
	RegAdminCmd("sm_ride", Cmd_ride, ADMFLAG_VOTE, "ride" );
	RegAdminCmd("sm_sexy", Cmd_sexy, ADMFLAG_VOTE, "sexy" );
	RegAdminCmd("sm_dada", Cmd_dada, ADMFLAG_VOTE, "dada" );
	RegAdminCmd("sm_nut", Cmd_nut, ADMFLAG_VOTE, "nut" );
	RegAdminCmd("sm_nob", Cmd_nob, ADMFLAG_VOTE, "nob" );
	RegAdminCmd("sm_coconut", Cmd_coconut, ADMFLAG_VOTE, "coconut" );
	RegAdminCmd("sm_ass", Cmd_ass, ADMFLAG_VOTE, "ass" );
	RegAdminCmd("sm_lotion", Cmd_lotion, ADMFLAG_VOTE, "lotion" );
	RegAdminCmd("sm_lotion2", Cmd_lotion2, ADMFLAG_VOTE, "lotion2" );
	RegAdminCmd("sm_smoker", Cmd_smoker, ADMFLAG_VOTE, "smoker" );
	RegAdminCmd("sm_gal", Cmd_gal, ADMFLAG_VOTE, "gal" ); 
	RegAdminCmd("sm_chicken", Cmd_chicken, ADMFLAG_VOTE, "chicken" );  
	RegAdminCmd("sm_brb", Cmd_brb, ADMFLAG_VOTE, "brb" ); 
	RegAdminCmd("sm_autobahn", Cmd_autobahn, ADMFLAG_VOTE, "autobahn" ); 
	RegAdminCmd("sm_cheese", Cmd_cheese, ADMFLAG_VOTE, "cheese" );
	RegAdminCmd("sm_order", Cmd_order, ADMFLAG_VOTE, "order" );
	RegAdminCmd("sm_cheese2", Cmd_cheese2, ADMFLAG_VOTE, "cheese2" );
	RegAdminCmd("sm_cheese3", Cmd_cheese3, ADMFLAG_VOTE, "cheese3" );
	RegAdminCmd("sm_hate", Cmd_hate, ADMFLAG_VOTE, "hate" );
	RegAdminCmd("sm_tards", Cmd_tards, ADMFLAG_VOTE, "tards" );
	RegAdminCmd("sm_feet", Cmd_feet, ADMFLAG_VOTE, "feet" );
	RegAdminCmd("sm_gabe", Cmd_gabe, ADMFLAG_VOTE, "gabe" );
	RegAdminCmd("sm_smac", Cmd_smac, ADMFLAG_VOTE, "smac" );
	RegAdminCmd("sm_corona", Cmd_corona, ADMFLAG_VOTE, "corona" );
	RegAdminCmd("sm_corona2", Cmd_corona2, ADMFLAG_VOTE, "corona2" );
	RegAdminCmd("sm_vip", Cmd_vip, ADMFLAG_VOTE, "vip" );
	RegAdminCmd("sm_canadians", Cmd_canadians, ADMFLAG_VOTE, "canadians" );
	RegAdminCmd("sm_canada", Cmd_canada, ADMFLAG_VOTE, "canada" );
	RegAdminCmd("sm_canada2", Cmd_canada2, ADMFLAG_VOTE, "canada2" );
	RegAdminCmd("sm_canada3", Cmd_canada3, ADMFLAG_VOTE, "canada3" );
	RegAdminCmd("sm_canada4", Cmd_canada4, ADMFLAG_VOTE, "canada4" );
	RegAdminCmd("sm_charming", Cmd_charming, ADMFLAG_VOTE, "charming" );
	RegAdminCmd("sm_nice", Cmd_nice, ADMFLAG_VOTE, "nice" );
	RegAdminCmd("sm_penis", Cmd_penis, ADMFLAG_VOTE, "penis" );
	RegAdminCmd("sm_door", Cmd_door, ADMFLAG_VOTE, "door" );
	RegAdminCmd("sm_beer", Cmd_beer, ADMFLAG_VOTE, "beer" );
	RegAdminCmd("sm_beer2", Cmd_beer2, ADMFLAG_VOTE, "beer2" );
	RegAdminCmd("sm_beer3", Cmd_beer3, ADMFLAG_VOTE, "beer3" );
	RegAdminCmd("sm_hersch", Cmd_hersch, ADMFLAG_VOTE, "hersch" );
	RegAdminCmd("sm_moron", Cmd_moron, ADMFLAG_VOTE, "moron" );
	RegAdminCmd("sm_moron2", Cmd_moron2, ADMFLAG_VOTE, "moron2" );
	RegAdminCmd("sm_peace", Cmd_peace, ADMFLAG_VOTE, "peace" );
	RegAdminCmd("sm_tanks", Cmd_tanks, ADMFLAG_VOTE, "tanks" );
	RegAdminCmd("sm_greta", Cmd_greta, ADMFLAG_VOTE, "greta" );
	RegAdminCmd("sm_greta2", Cmd_greta2, ADMFLAG_VOTE, "greta2" );
	RegAdminCmd("sm_aye", Cmd_aye, ADMFLAG_VOTE, "aye" );
	RegAdminCmd("sm_louis", Cmd_louis, ADMFLAG_VOTE, "louis" );
	RegAdminCmd("sm_tied", Cmd_tied, ADMFLAG_VOTE, "tied" );
	RegAdminCmd("sm_move", Cmd_move, ADMFLAG_VOTE, "move" );
	RegAdminCmd("sm_bastids", Cmd_bastids, ADMFLAG_VOTE, "bastids" );
	RegAdminCmd("sm_anything", Cmd_anything, ADMFLAG_VOTE, "anything" );
	RegAdminCmd("sm_hlp", Cmd_hlp, ADMFLAG_VOTE, "hlp" );
	RegAdminCmd("sm_poop", Cmd_poop, ADMFLAG_VOTE, "poop" );
	RegAdminCmd("sm_lasagna2", Cmd_lasagna2, ADMFLAG_VOTE, "lasagna2" );
	RegAdminCmd("sm_it", Cmd_it, ADMFLAG_VOTE, "it" );
	RegAdminCmd("sm_zombie", Cmd_zombie, ADMFLAG_VOTE, "zombie" );
	RegAdminCmd("sm_saints", Cmd_saints, ADMFLAG_VOTE, "saints" );
	RegAdminCmd("sm_xmas", Cmd_xmas, ADMFLAG_VOTE, "xmas" );
	RegAdminCmd("sm_triumph", Cmd_triumph, ADMFLAG_VOTE, "triumph" );
	RegAdminCmd("sm_firewall", Cmd_firewall, ADMFLAG_VOTE, "firewall" );
	RegAdminCmd("sm_gb", Cmd_gb, ADMFLAG_VOTE, "gb" );
	RegAdminCmd("sm_eww", Cmd_eww, ADMFLAG_VOTE, "eww" );
	RegAdminCmd("sm_fullauto", Cmd_fullauto, ADMFLAG_VOTE, "fullauto" );
	RegAdminCmd("sm_witch", Cmd_witch, ADMFLAG_VOTE, "witch" );
	RegAdminCmd("sm_niet", Cmd_niet, ADMFLAG_VOTE, "niet" );
	RegAdminCmd("sm_monkey", Cmd_monkey, ADMFLAG_VOTE, "monkey" );

	RegConsoleCmd("sm_hb", Cmd_hb, "hb" );
	RegAdminCmd("sm_soundboard", Cmd_soundboard, ADMFLAG_VOTE, "print all commands" );

	PrecacheSound("common\\null.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\deathscream04.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	PrecacheSound("music\\flu\\jukebox\\all_i_want_for_xmas.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3intanktraincar07.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3firstsaferoom01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpressgen202.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\witchgettingangry07.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	PrecacheSound("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar01.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\takesubmachinegun03.wav");
	PrecacheSound("music\\flu\\jukebox\\re_your_brains.wav");
	PrecacheSound("music\\flu\\jukebox\\badman.wav");
	PrecacheSound("music\\flu\\jukebox\\midnightride.wav");
	PrecacheSound("music\\flu\\jukebox\\save_me_some_sugar_mono.wav");
	PrecacheSound("music\\flu\\jukebox\\thesaintswillnevercome.wav");
	PrecacheSound("music\\flu\\jukebox\\portal_still_alive.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\goingtodielight13.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\closethedoor07.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2hersch01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2gastanks03.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3intro25.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3billdies01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\exertioncritical01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadahate01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadahate02.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\dlc2swearcoupdegrace17.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadaspecial01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2canadaspecial02.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2bulletinboard02.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom08.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\dlc2intro09.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom09.wav");
	PrecacheSound("player\\survivor\\voice\\manager\\c6dlc3jumpingoffbridge19.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\alertgiveitem09.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\youarewelcome39.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\nicejob07.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\reactionpositive27.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2riverside03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\taunt29.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\taunt34.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\killthatlight13.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\laughter16.wav");
	PrecacheSound("ui\\pickup_secret01.wav");
	PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_4.wav");
	PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_7.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2bulletinboard02.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2gastanks01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2steam01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\sorry12.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\answerready05.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpresslift01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2pilotcomment01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2pilotcomment02.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\deathscream03.wav");
	PrecacheSound("buttons\\bell1.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3intro14.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended35.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor05.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2bulletinboard01.wav");
	PrecacheSound("npc\\witch\\voice\\idle\\female_cry_2.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\hurrah18.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom13.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom11.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\heardsmoker06.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2magazinerack01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3tankintrainyard10.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor06.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\c6dlc3jumpingoffbridge17.wav");
	PrecacheSound("animation\\van_inside_start.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\exertionmajor01.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\exertioncritical03.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\takepipebomb04.wav");
	PrecacheSound("player\\survivor\\voice\\teengirl\\dlc2misc01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming07.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\nervoushumming06.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2recycling01.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\dlc2recycling02.wav");
	PrecacheSound("player\\survivor\\voice\\biker\\c6dlc3intro23.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\worldsmalltownnpcbellman07.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3communitylines04.wav");
	PrecacheSound("commentary\\com-intro.wav");
	PrecacheSound("npc\\churchguy\\radiocombatcolor02.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended40.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended21.wav");
	PrecacheSound("npc\\churchguy\\radiobutton1extended28.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3movieline10.wav");
	PrecacheSound("common\\bugreporter_failed.wav");
	PrecacheSound("player\\survivor\\voice\\namvet\\c6dlc3movieline05.wav");
}



public Action Cmd_monkey(int client,int args)
{
	Command_Play("player\\survivor\\voice\\manager\\deathscream04.wav");
	Command_Play("player\\survivor\\voice\\manager\\deathscream04.wav");
	PrintToChatAll("Excuse me?");
	return Plugin_Handled;
}

public Action Cmd_niet(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("No no no no nooooo!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	Command_Play("player\\survivor\\voice\\teengirl\\grabbedbysmoker03a.wav");
	return Plugin_Handled;
}

public Action Cmd_xmas(int client,int args)
{

	Command_Play("music\\flu\\jukebox\\all_i_want_for_xmas.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("HO HO HO MERRY ASSMAS!!!!");
	PrintToChatAll("******************************************************");

	return Plugin_Handled;
}
public Action Cmd_eww(int client,int args)
{

	Command_Play("player\\survivor\\voice\\manager\\c6dlc3intanktraincar07.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("Ewww, that's some gross ass shit!!!!");
	PrintToChatAll("******************************************************");

	return Plugin_Handled;
}
public Action Cmd_gb(int client,int args)
{

	Command_Play("player\\survivor\\voice\\manager\\c6dlc3firstsaferoom01.wav");
	PrintToChatAll("******************************************************");
	PrintToChatAll("Good night!!!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}

public Action Cmd_move(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Move already you stupid ******!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpressgen202.wav");
	return Plugin_Handled;
}
public Action Cmd_witch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("DON'T PISS OFF THE WITCH!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\witchgettingangry07.wav");
	return Plugin_Handled;
}

public Action Cmd_bastids(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("niet cry here plz");
	PrintToChatAll("******************************************************");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	return Plugin_Handled;
}

public Action Cmd_fullauto(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("S FUCKING MG!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\takesubmachinegun03.wav");
	return Plugin_Handled;
}


public Action Cmd_zombie(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("They are Zombies, Francis. ZOMBIES!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\re_your_brains.wav");
	return Plugin_Handled;
}

public Action Cmd_bad(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("BAD MAN TG!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\badman.wav");
	return Plugin_Handled;
}
public Action Cmd_ride(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Niet survive that ride, dude.");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\midnightride.wav");
	return Plugin_Handled;
}
public Action Cmd_sugar(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Give me some sugar, baby.");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\save_me_some_sugar_mono.wav");
	return Plugin_Handled;
}
public Action Cmd_saints(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("What's not to like?");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\thesaintswillnevercome.wav");
	return Plugin_Handled;
}

public Action Cmd_triumph(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("This was a triumph!");
	PrintToChatAll("******************************************************");
	Command_Play("music\\flu\\jukebox\\portal_still_alive.wav");
	return Plugin_Handled;
}


public Action Cmd_poop(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Taking a dump.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\goingtodielight13.wav");
	return Plugin_Handled;
}
public Action Cmd_door(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Close the FUCKING door.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\closethedoor07.wav");
	return Plugin_Handled;
}
public Action Cmd_hersch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("o0");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2hersch01.wav");
	return Plugin_Handled;
}
public Action Cmd_vip(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("VIP = very important pidor");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2gastanks03.wav");
	return Plugin_Handled;
}

public Action Cmd_aye(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Aye Aye Captain!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3intro25.wav");
	return Plugin_Handled;
}
public Action Cmd_louis(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll(":D");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3billdies01.wav");
	return Plugin_Handled;
}

public Action Cmd_cheese2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("o0");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\exertioncritical01.wav");
	return Plugin_Handled;
}
public Action Cmd_canada(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadahate01.wav");
	return Plugin_Handled;
}
public Action Cmd_canada2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadahate02.wav");
	return Plugin_Handled;
}
public Action Cmd_bitch(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("*** *** Troll ****!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\dlc2swearcoupdegrace17.wav");
	return Plugin_Handled;
}
public Action Cmd_canada3(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadaspecial01.wav");
	return Plugin_Handled;
}

public Action Cmd_canada4(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I hate Canada!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2canadaspecial02.wav");
	return Plugin_Handled;
}


public Action Cmd_lasagna2(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I love lasagna!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2bulletinboard02.wav");
	return Plugin_Handled;
}
public Action Cmd_it(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("I know how you feel!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom08.wav");
	return Plugin_Handled;
}
public Action Cmd_parade(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("yeah and join Francis.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\dlc2intro09.wav");
	return Plugin_Handled;
}


public Action Cmd_firewall(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("*shakes head sadly*");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3secondsaferoom09.wav");
	return Plugin_Handled;
}
public Action Cmd_hlp(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Help the ADMIN! HELP!!!!!!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\manager\\c6dlc3jumpingoffbridge19.wav");
	return Plugin_Handled;
}
public Action Cmd_chocolate(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Here my friend, chocolate for you!" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\alertgiveitem09.wav");
	return Plugin_Handled;
}
public Action Cmd_anything(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Anything?" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\youarewelcome39.wav");
	return Plugin_Handled;
}

public Action Cmd_nice(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("THAT WAS GREAT!" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\nicejob07.wav");
	return Plugin_Handled;
}
public Action Cmd_charming(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("0o" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\reactionpositive27.wav ");
	return Plugin_Handled;
}
public Action Cmd_canadians(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Canadians are dicks!" );
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\dlc2riverside03.wav");
	return Plugin_Handled;
}
public Action Cmd_ds(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("We LOVE ds, sorry!" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_vodka(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You Gin? I Vodka!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\taunt29.wav");
	return Plugin_Handled;
}

public Action Cmd_gin(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I Vodka! You Gin?" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\taunt34.wav");
	return Plugin_Handled;
}

public Action Cmd_socks(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("... oh and how to knit socks!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom03.wav");
	return Plugin_Handled;
}

public Action Cmd_hax(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("TURN IT OFF!!!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\killthatlight13.wav");
	return Plugin_Handled;
}
public Action Cmd_tickle(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("hahaha STOP THAT!!!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\laughter16.wav");
	return Plugin_Handled;
}
public Action Cmd_fuckoff(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("The Banhammer Has Spoken!" );
	PrintToChatAll("******************************************************");
	Command_Play("ui\\pickup_secret01.wav");
	Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");
	return Plugin_Handled;
}
public Action Cmd_banhammer(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("STOP NOW OR FEEL THE BANHAMMER!" );
	PrintToChatAll("******************************************************");
	Command_Play("ui\\pickup_secret01.wav");
	Command_Play("player\\tank\\voice\\yell\\hulk_yell_7.wav");
	return Plugin_Handled;
}

public Action Cmd_lasagna(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate mondays!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2bulletinboard02.wav");
	return Plugin_Handled;
}
public Action Cmd_fart(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I fart in your general direction!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2gastanks01.wav");
	return Plugin_Handled;
}
public Action Cmd_steam(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Man I love Steam!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2steam01.wav");
	return Plugin_Handled;
}
public Action Cmd_pee(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Sorry, have to pee, brb" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\sorry12.wav");
	return Plugin_Handled;
}
public Action Cmd_sex(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\answerready05.wav");
	return Plugin_Handled;
}
public Action Cmd_sex2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2m2finalebuttonpresslift01.wav");
	return Plugin_Handled;
}
public Action Cmd_license(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2pilotcomment01.wav");
	return Plugin_Handled;
}
public Action Cmd_license2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2pilotcomment02.wav");
	return Plugin_Handled;
}
public Action Cmd_orgasm(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Oo" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\deathscream03.wav");
	return Plugin_Handled;
}
public Action Cmd_love(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Oh, good morning, going down?");
	PrintToChatAll("******************************************************");
	Command_Play("buttons\\bell1.wav");
	return Plugin_Handled;
}
public Action Cmd_anus(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("plz, clean yourself. plz");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3intanktraincar03.wav");
	return Plugin_Handled;
}
public Action Cmd_corona(int client,int args)
{
	PrintToChatAll("******************************************************");
	PrintToChatAll("Sure, it's the rest of the world we can just let die");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3intro14.wav");
	return Plugin_Handled;
}
public Action Cmd_corona2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("CORONA!!!!!!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended35.wav");
	return Plugin_Handled;
}

public Action Cmd_anal(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I cannot believe I'm doing this!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor05.wav");
	return Plugin_Handled;
}
public Action Cmd_sexy(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("It was my first and only visit to an allgirl's camp.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2bulletinboard01.wav");

	return Plugin_Handled;
}
public Action Cmd_cry(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("niet cry here plz");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\witch\\voice\\idle\\female_cry_2.wav");
	return Plugin_Handled;
}


public Action Cmd_dada(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Dada Spasibo!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_nut(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't make me get the nut-cracker!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_pidor(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("ro pidors");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_nob(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You're a cheating doorknob!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_ass(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("It's time to kick ass and chew bubble gum and I'm all out of gum.");
	PrintToChatAll("******************************************************");
        Command_Play("player\\survivor\\voice\\teengirl\\hurrah18.wav");
	return Plugin_Handled;
}
public Action Cmd_lotion(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate puttin' the lotion in the basket!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom13.wav");
	return Plugin_Handled;
}
public Action Cmd_lotion2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate puttin' the lotion in the basket!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3secondsaferoom11.wav");
	return Plugin_Handled;
}
public Action Cmd_smoker(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Smoker damage; Best russian invention EVER.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\heardsmoker06.wav");
	return Plugin_Handled;
}
public Action Cmd_hate(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Hate Magazine 1 - I hate DDOS.");	
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2magazinerack01.wav");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}

public Action Cmd_gal(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("No BANFUCKING way I'm doing this.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3tankintrainyard10.wav");
	return Plugin_Handled;
}
public Action Cmd_chicken(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("unFUCKING believable");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3openingdoor06.wav");
	return Plugin_Handled;
}
public Action Cmd_brb(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("1 sec. I'll be back.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\c6dlc3jumpingoffbridge17.wav");
	return Plugin_Handled;
}
public Action Cmd_autobahn(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("AUTOBAAAAAAAAAAAAAAAAAAHN!");
	PrintToChatAll("******************************************************");
	Command_Play("animation\\van_inside_start.wav");
	return Plugin_Handled;
}
public Action Cmd_cheese(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I'm in dire need of melted cheese!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\exertionmajor01.wav");
	return Plugin_Handled;
}
public Action Cmd_cheese3(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I'm in dire need of melted cheese!" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\exertioncritical03.wav");
	return Plugin_Handled;
}
public Action Cmd_penis(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("oO" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\takepipebomb04.wav");
	return Plugin_Handled;
}
public Action Cmd_easy(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("... when you're on easy street" );
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\teengirl\\dlc2misc01.wav");
	return Plugin_Handled;
}

public Action Cmd_tards(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Cards with the tards. Who could beat a night of cards, chips, dips and dorks?" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_smac(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("SMAC -> super moist ass crack!" );
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_hb(int client,int args)
{
        PrintToChatAll("\x04[\x03HB\x04] Placebo heartbeat sent from all clients.. but not really." );
	return Plugin_Handled;
}
public Action Cmd_beer(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming07.wav");

	return Plugin_Handled;
}
public Action Cmd_beer2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming01.wav");


	return Plugin_Handled;
}
public Action Cmd_beer3(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("More beer!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\nervoushumming06.wav");

	return Plugin_Handled;
}
public Action Cmd_greta(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You are the Greta Thunberg of Left4Dead!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2recycling01.wav");
	return Plugin_Handled;
}
public Action Cmd_greta2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("You are the Greta Thunberg of Left4Dead!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\dlc2recycling02.wav");
	return Plugin_Handled;
}
public Action Cmd_coconut(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I hate islands!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\biker\\c6dlc3intro23.wav");
	return Plugin_Handled;
}
public Action Cmd_moron(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't bother talking to me. thx");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\worldsmalltownnpcbellman07.wav");
	return Plugin_Handled;
}
public Action Cmd_feet(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Tell me more bro!");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3communitylines04.wav");
	return Plugin_Handled;
}
public Action Cmd_gabe(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("I won't fix this game!");
	PrintToChatAll("******************************************************");
	Command_Play("commentary\\com-intro.wav");
	return Plugin_Handled;
}

public Action Cmd_save(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Better save than sorry!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiocombatcolor02.wav");
	return Plugin_Handled;
}
public Action Cmd_save2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Ding Dong!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended40.wav");
	return Plugin_Handled;
}
public Action Cmd_moron2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll(" Don't bother talking to me. thx!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended21.wav");
	return Plugin_Handled;
}
public Action Cmd_bitch2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("S*** Up Troll B***!");
	PrintToChatAll("******************************************************");
	Command_Play("npc\\churchguy\\radiobutton1extended28.wav");
	return Plugin_Handled;
}
public Action Cmd_order(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("ORDER! ORDEEER! OOOORDER!!!");
	PrintToChatAll("******************************************************");
	return Plugin_Handled;
}
public Action Cmd_banhammer2(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("BAAAANHAAMMMMMMERRRRRRR!!");
	PrintToChatAll("******************************************************");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_1.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_2.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_3.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	Command_Play("ambient\\weather\\thunderstorm\\lightning_strike_4.wav");
	return Plugin_Handled;
}

public Action Cmd_peace(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Don't bother talking to me. thx");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3movieline10.wav");
	return Plugin_Handled;
}
public Action Cmd_tied(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("We LOVE tied teams message!");
	PrintToChatAll("******************************************************");
	Command_Play("common\\bugreporter_failed.wav");
	Command_Play("common\\bugreporter_failed.wav");
	Command_Play("common\\bugreporter_failed.wav");
	return Plugin_Handled;
}

public Action Cmd_tanks(int client,int args)
{
        PrintToChatAll("******************************************************");
	PrintToChatAll("Now that was one shitty tank. Punk.");
	PrintToChatAll("******************************************************");
	Command_Play("player\\survivor\\voice\\namvet\\c6dlc3movieline05.wav");
	return Plugin_Handled;
}



public Action Cmd_soundboard(int client,int args)
{
        PrintToChatAll("!chocolate !lasagna !lasagna2 !vodka !gin !nut");
        PrintToChatAll("!cheese !cheese2 !cheese3 !anal !sex !sex2 !penis !orgasm !love !tickle");
        PrintToChatAll("!eww !cry !monkey !niet !pee !brb !poop !ass !fart");
        PrintToChatAll("!anus !corona !corona2 !fullauto !witch !greta !greta2 !bastids");
        PrintToChatAll("!smoker !smac !coconut !gal !bitch !bitch2");
        PrintToChatAll("!ds !socks !hax !steam !nob !tards !smac !hate !tanks");
        PrintToChatAll("!dada !pidor !nice !charming !lotion !lotion2 !chicken !parade");
        PrintToChatAll("!it !firewall !autobahn !beer !beer2 !beer3 !moron !moron2 !peace");
        PrintToChatAll("!canadians !canada !canada2 !canada3 !canada4 ");
	PrintToChatAll("!license !license2 !sexy !aye !louis !hlp !tied !door !gb ");
	PrintToChatAll("!save !save2 !easy !order !feet !anything !vip !move !hersch");
	PrintToChatAll("!sugar !ride !bad !zombie !saints !triumph !xmas !gabe");
        PrintToChatAll("!fuckoff !banhammer !banhammer2 !soundboard");
	return Plugin_Handled;
}



public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);

	}  
	//return Plugin_Handled;
}

