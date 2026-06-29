#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "vocalizefatigue"

public Plugin:myinfo =
{ 
	name = "[L4D2] Model Based Vocalizations Part 1",
	author = "DeathChaos, cravenge",
	description = "Vocalizations Now Vary Depending On Survivor Models.",
	version = "2.6",
	url = ""
};

static const String:g_Coach[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07",
	"Laughter01", "Laughter04", "Laughter06", "Laughter07", "Laughter13", "Laughter14", "Laughter22",
	"Yes03", "Yes05", "Yes07", "Yes10",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No10", "No11", "No12", "WorldC2M132", "WorldC5M3B13", "WorldC5M5B04", "WorldSigns24", "WorldSigns26",
	"WorldC3M207", "AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady06", "AskReady07", "AskReady08",
	"ReactionNegative01", "ReactionNegative02", "ReactionNegative03", "ReactionNegative07", "ReactionNegative08", "ReactionNegative09", "ReactionNegative10", "ReactionNegative14", "ReactionNegative15", "ReactionNegative17", "ReactionNegative18", "ReactionNegative19", "WorldC5M4B03", "WorldC5M3B28",
	"BattleCry04", "BattleCry06", "BattleCry09", "Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "Hurrah12", "Hurrah13", "Hurrah14", "Hurrah15", "Hurrah16", "Hurrah17", "Hurrah18", "Hurrah19", "Hurrah20", "Hurrah21", "Hurrah23", "Hurrah24", "Hurrah26", "PositiveNoise03", "PositiveNoise10",
	"Thanks01", "Thanks02", "Thanks04", "Thanks05", "Thanks06", "Thanks07",
	"DLC1_C6M2_SuitcasePistols01", "Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt06", "Taunt07", "Taunt08", "WorldC2M2B05", "WorldC2M2B06", "WorldC3M116", "WorldC3M117",
	"LookOut01", "LookOut02", "LookOut03", "LookOut04",
	"Reloading01", "Reloading02", "Reloading03", "Reloading04", "Reloading05", "Reloading06", "Reloading07",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HurtMajor07", "HurtMajor08", "HurtMajor09", "HurtMajor10", "HurtMajor11",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial04",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06", "HurtCritical07", "HurtCritical08",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04",
	"CallForRescue01", "CallForRescue06", "CallForRescue09", "CallForRescue11", "CallForRescue13", "CallForRescue16", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "LedgeHangMiddle02", "LedgeHangStart01", "LedgeHangStart02", "LedgeHangStart03",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08", "CoverMeC101", "CoverMeC102", "CoverMeC103", "CoverMeC104",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03", "PainRelieftFirstAid04",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "MoveOn08", "MoveOn09", "MoveOn10", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05", "FollowMe06",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04", "ImWithYou05", "ImWithYou06",
	"PainRelieftPills01", "PainRelieftPills02", "PainRelieftPills03", "PainRelieftPills04", "PainRelieftPills05", "PainRelieftPills06",
	"YouAreWelcome01", "YouAreWelcome02", "YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11", "GettingRevived12", "GettingRevived13", "GettingRevived14", "GettingRevived15", "GettingRevived16", "GettingRevived17", "GettingRevived18", "GettingRevived19", "GettingRevived20", "GettingRevived21", "GettingRevived22", "GettingRevived23", "GettingRevived24", "GettingRevived25", "GettingRevived26", "GettingRevived27", "GettingRevived28", "GettingRevived29", "GettingRevived30", "GettingRevived31", "GettingRevived32", "GettingRevived33", "GettingRevived34", "GettingRevived35", "GettingRevived36", "GettingRevived37",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend13", "ReviveFriend14", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA06", "ReviveFriendA07", "ReviveFriendA08", "ReviveFriendA09", "ReviveFriendA10", "ReviveFriendA11", "ReviveFriendA12", "ReviveFriendA13", "ReviveFriendA14", "ReviveFriendA15", "ReviveFriendA16", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendB15", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05", "ReviveCriticalFriend06", "ReviveCriticalFriend07",
	"Grenade08", "Grenade09", "Grenade10", "Grenade01", "Grenade02", "Grenade03", "Grenade04", "Grenade05", "Grenade06", "Grenade07", "Grenade11", "Grenade12", "BoomerJar09", "BoomerJar10", "BoomerJar11",
	"Defibrillator05", "Defibrillator06", "Defibrillator07", "Defibrillator08", "Defibrillator09", "Defibrillator10", "Defibrillator11", "Defibrillator12", "Defibrillator13", "Defibrillator14", "Defibrillator15", "Defibrillator16", "Defibrillator17", "Defibrillator18", "Defibrillator19",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp07", "HurryUp08", "HurryUp09", "HurryUp10", "HurryUp11",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10", "NiceJob11", "NiceJob12", "NiceJob13", "NiceJob14", "NiceJob15",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04", "ToTheRescue05", "ToTheRescue06",
	"WarnCareful01", "WarnCareful02", "WarnCareful03", "WarnCareful04",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04", "WaitHere05", "WaitHere06",
	"GrabbedBySmoker01", "GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker01C", "GrabbedBySmoker01D", "GrabbedBySmoker02", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker02C", "GrabbedBySmoker02D", "GrabbedBySmoker02E", "GrabbedBySmoker03", "GrabbedBySmoker03A", "GrabbedBySmoker03B", "GrabbedBySmoker03C", "GrabbedBySmoker04", "GrabbedBySmoker04A", "GrabbedBySmoker04B", "GrabbedBySmoker04C", "GrabbedBySmoker04D", "GrabbedBySmokerC101", "GrabbedBySmokerC102", "GrabbedBySmokerC103", "GrabbedBySmokerC104"
};

static const String:g_Nick[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08",
	"Laughter01", "Laughter03", "Laughter06", "Laughter15", "Laughter16", "Laughter17",
	"Yes01", "Yes04", "Yes05", "Yes08",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No10", "No11", "No12", "EllisInterrupt03",
	"AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady06", "AskReady07", "AskReady08", "AskReady09", "AskReady10", "AskReadyC101", "AskReadyC102", "AskReadyC103",
	"ReactionNegative01", "ReactionNegative02", "ReactionNegative04", "ReactionNegative08", "ReactionNegative09", "ReactionNegative13", "ReactionNegative14", "ReactionNegative15", "ReactionNegative16", "ReactionNegative17", "ReactionNegative18", "ReactionNegative19", "WorldC5M4B06", "WorldC5M4B07", "ReactionNegative20", "ReactionNegative21", "ReactionNegative22", "ReactionNegative23", "ReactionNegative24", "ReactionNegative34", "ReactionNegative36", "ReactionNegative37", "ReactionNegative38",
	"Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "BattleCry01", "BattleCry04",
	"Thanks01", "Thanks03", "Thanks05",
	"Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt06", "Taunt07", "Taunt08", "Taunt09",
	"LookOut01", "LookOut02", "LookOut03",
	"Reloading01", "Reloading02", "Reloading03", "Reloading04", "Reloading05", "Reloading06", "Reloading07",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HurtMajor07", "HurtMajor08", "HurtMajor09", "HurtMajor10", "HurtMajor11",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial04",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06", "HurtCritical07",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04",
	"CallForRescue05", "CallForRescue06", "CallForRescue12", "Help01", "Help02", "Help03", "Help04", "Help05", "LedgeHangEnd01", "LedgeHangEnd03", "LedgeHangMiddle02", "LedgeHangMiddle03", "LedgeHangMiddle04", "LedgeHangStart03", "LedgeHangStart04",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08", "CoverMe09", "CoverMeC101", "CoverMeC102", "CoverMeC103", "CoverMeC104", "CoverMeC105",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03", "PainRelieftFirstAid04", "PainRelieftFirstAid05", "PainRelieftFirstAid06", "PainRelieftFirstAid07",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOtherC101", "HealOtherC102", "HealOtherC103", "HealOtherC104", "HealOtherC105",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05", "FollowMe06", "FollowMe07", "FollowMe08", "FollowMe09", "FollowMe10", "FollowMe11", "FollowMe12", "FollowMe13",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05", "LeadOn06", "LeadOn07", "LeadOn08", "LeadOn09",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04", "ImWithYou05",
	"PainRelieftPills01", "PainRelieftPills02", "PainRelieftPills03", "PainRelieftPills04", "PainRelieftPills05",
	"YouAreWelcome01", "YouAreWelcome02", "YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome06", "YouAreWelcome07", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome10", "YouAreWelcome11", "YouAreWelcome12", "YouAreWelcome13", "YouAreWelcome14", "YouAreWelcome15", "YouAreWelcome16", "YouAreWelcome17",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11", "GettingRevived12", "GettingRevived13", "GettingRevived14", "GettingRevived15", "GettingRevived16", "GettingRevived17", "GettingRevived18", "GettingRevived19", "GettingRevived20",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend13", "ReviveFriend14", "ReviveFriend15", "ReviveFriend16", "ReviveFriend17", "ReviveFriend18", "ReviveFriend19", "ReviveFriend20", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA06", "ReviveFriendA07", "ReviveFriendA08", "ReviveFriendA09", "ReviveFriendA10", "ReviveFriendA11", "ReviveFriendA12", "ReviveFriendA13", "ReviveFriendA14", "ReviveFriendA15", "ReviveFriendA16", "ReviveFriendA17", "ReviveFriendA18", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03",
	"Grenade03", "Grenade04", "Grenade06", "Grenade08", "Grenade10", "Grenade12", "Grenade01", "Grenade02", "Grenade05", "Grenade07", "Grenade09", "Grenade11", "Grenade13", "BoomerJar08", "BoomerJar09", "BoomerJar10",
	"Defibrillator06", "Defibrillator07", "Defibrillator08", "Defibrillator09", "Defibrillator18", "Defibrillator10", "Defibrillator11", "Defibrillator12", "Defibrillator13", "Defibrillator14", "Defibrillator15", "Defibrillator16", "Defibrillator17",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04",
	"WarnCareful01", "WarnCareful02", "WarnCareful03",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04", "WaitHere05",
	"GrabbedBySmoker01", "GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker02", "GrabbedBySmoker02A", "GrabbedBySmoker03", "GrabbedBySmoker04", "GrabbedBySmoker04A", "GrabbedBySmoker05", "GrabbedBySmoker05A", "GrabbedBySmoker05B", "GrabbedBySmoker05C", "GrabbedBySmokerC101", "GrabbedBySmokerC102", "GrabbedBySmokerC103", "GrabbedBySmokerC104", "GrabbedBySmokerC105"
};

static const String:g_Ellis[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09", "Sorry10",
	"Laughter04", "Laughter05", "Laughter06", "Laughter09", "Laughter13B", "Laughter13C", "Laughter13D", "Laughter13E", "WorldC2M2B23", "Laughter14",
	"Yes01", "Yes03", "Yes06",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No10", "No11", "No12",
	"AskReady01", "AskReady02", "AskReady03",
	"ReactionNegative02", "ReactionNegative04", "ReactionNegative05", "ReactionNegative06", "ReactionNegative07", "ReactionNegative08", "ReactionNegative13", "ReactionNegative14", "ReactionNegative17", "ReactionNegative18", "ReactionNegative19", "ReactionNegative20", "TeamKillAccident05",
	"Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "Hurrah12", "Hurrah13", "Hurrah14", "Hurrah15", "Hurrah18", "TransitionClose01", "TransitionClose04", "TransitionClose06", "WorldC1M4B63", "WorldC2M5B47",
	"Thanks02", "Thanks04", "Thanks05",
	"Hurrah20", "Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt07", "Taunt08", "TransitionClose11", "WorldC2M2B05", "WorldC2M2B06",
	"LookOut01", "LookOut02", "LookOut03",
	"Reloading01", "Reloading02", "Reloading03", "Reloading04", "Reloading05", "Reloading06",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07", "HurtMinor08", "HurtMinor09",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04", "IncapacitatedInjury05", "IncapacitatedInjury06",
	"CallForRescue04", "CallForRescue06", "CallForRescue07", "CallForRescue09", "CallForRescue12", "CallForRescue13", "CallForRescue14", "CallForRescue18", "CallForRescue19", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "LedgeHangEnd01", "LedgeHangEnd02", "LedgeHangEnd04", "LedgeHangFall01", "LedgeHangMiddle02", "LedgeHangMiddle04", "LedgeHangMiddle05", "LedgeHangStart02",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08", "CoverMeC101", "CoverMeC102",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03", "PainRelieftFirstAid04", "PainRelieftFirstAid05", "PainRelieftFirstAid06",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07", "HealOther08", "HealOther09", "HealOtherC103", "HealOtherC104", "HealOtherC105",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04",
	"PainRelieftPills01", "PainRelieftPills02", "PainRelieftPills03", "PainRelieftPills04", "PainRelieftPills05", "PainRelieftPills06", "PainRelieftPills07", "PainRelieftPills08",
	"YouAreWelcome01", "YouAreWelcome02", "YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome06", "YouAreWelcome07", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome10",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11", "GettingRevived12", "GettingRevived13", "GettingRevived14", "GettingRevived15", "GettingRevived16", "GettingRevived17", "GettingRevived18", "GettingRevived19", "GettingRevived20", "GettingRevived21", "GettingRevived22", "GettingRevived23", "GettingRevived24", "GettingRevived25",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA06", "ReviveFriendA07", "ReviveFriendA08", "ReviveFriendA09", "ReviveFriendA10", "ReviveFriendA11", "ReviveFriendA12", "ReviveFriendA13", "ReviveFriendA14", "ReviveFriendA15", "ReviveFriendA16", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendB15", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03",
	"Grenade05", "Grenade06", "Grenade08", "Grenade10", "Grenade01", "Grenade02", "Grenade09", "Grenade11", "Grenade13", "Grenade03", "Grenade04", "Grenade07", "Grenade12", "BoomerJar08", "BoomerJar09", "BoomerJar10", "BoomerJar11", "BoomerJar12", "BoomerJar13", "BoomerJar14",
	"Defibrillator07", "Defibrillator08", "Defibrillator09", "Defibrillator10", "Defibrillator11", "Defibrillator12", "Defibrillator13", "Defibrillator14", "Defibrillator16", "Defibrillator17", "Defibrillator18", "Defibrillator19",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp07",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10", "NiceJob11", "NiceJob12",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04", "ToTheRescue05", "ToTheRescue06", "ToTheRescue07",
	"WarnCareful01", "WarnCareful02", "WarnCareful03", "WarnCareful04", "WarnCareful05",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04",
	"GrabbedBySmoker01", "GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker01C", "GrabbedBySmoker01D", "GrabbedBySmoker01E", "GrabbedBySmoker02", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker03", "GrabbedBySmoker03A", "GrabbedBySmoker03B", "GrabbedBySmoker03C", "GrabbedBySmoker03D", "GrabbedBySmoker04", "GrabbedBySmoker05", "GrabbedBySmoker06", "GrabbedBySmoker06A", "GrabbedBySmoker06B", "GrabbedBySmoker06C", "GrabbedBySmokerC101", "GrabbedBySmokerC102", "GrabbedBySmokerC103", "GrabbedBySmokerC104", "GrabbedBySmokerC105", "GrabbedBySmokerC106"
};

static const String:g_Rochelle[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "WitchChasing08",
	"Laughter01", "Laughter04", "Laughter12", "Laughter13", "Laughter14", "Laughter17",
	"Yes01", "Yes05", "Yes07", "Yes08",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No10", "No11", "No12", "DLC1_C6M3_FinaleChat17", "DLC1_C6M3_FinaleChat18", "DLC1_C6M3_FinaleChat20",
	"AskReady01", "AskReady02", "AskReady03",
	"ReactionNegative01", "ReactionNegative02", "ReactionNegative03", "ReactionNegative05", "ReactionNegative06", "ReactionNegative08", "ReactionNegative09", "ReactionNegative10", "ReactionNegative11", "ReactionNegative12", "ReactionNegative20", "ReactionNegative21", "DLC1_C6M1_InitialMeeting34", "DLC1_C6M1_InitialMeeting35", "DLC1_C6M1_InitialMeeting36",
	"MeleeResponse02", "TakeMelee07", "TransitionClose03", "TransitionClose08", "WorldC1M4B38", "WorldC2M2B28", "Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "Hurrah12",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks05", "DLC1_C6M1_InitialMeeting18", "DLC1_C6M1_InitialMeeting19",
	"Taunt01", "Taunt02", "Taunt03", "Taunt05", "Taunt06", "Taunt07",
	"LookOut01", "LookOut02", "LookOut03",
	"Reloading01", "Reloading02", "Reloading03", "Reloading04",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial04",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04",
	"CallForRescue01", "CallForRescue02", "CallForRescue03", "CallForRescue06", "CallForRescue07", "CallForRescue08", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "Help07", "Help08", "LedgeHangEnd01", "LedgeHangEnd02", "LedgeHangMiddle02", "LedgeHangStart02", "LedgeHangStart03", "LedgeHangStart04",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMeC101",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03", "PainRelieftFirstAid04", "PainRelieftFirstAid05",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05", "LeadOn06", "LeadOn07", "LeadOn08", "LeadOn09", "LeadOn10",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04", "ImWithYou05", "ImWithYou06",
	"PainRelieftPills01", "PainRelieftPills02", "PainRelieftPills03", "PainRelieftPills04", "PainRelieftPills05",
	"YouAreWelcome01", "YouAreWelcome02", "YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome06", "YouAreWelcome07", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome10",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11", "GettingRevived12", "GettingRevived13", "GettingRevived14", "GettingRevived15", "GettingRevived16", "GettingRevived17", "GettingRevived18", "GettingRevived19", "GettingRevived20", "GettingRevived21", "GettingRevived22", "GettingRevived23",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend13", "ReviveFriend14", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA06", "ReviveFriendA07", "ReviveFriendA08", "ReviveFriendA09", "ReviveFriendA10", "ReviveFriendA11", "ReviveFriendA12", "ReviveFriendA13", "ReviveFriendA14", "ReviveFriendA15", "ReviveFriendA16", "ReviveFriendA17", "ReviveFriendA18", "ReviveFriendA19", "ReviveFriendA20", "ReviveFriendA21", "ReviveFriendA22", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07", "ReviveFriendLoud08",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05",
	"Grenade03", "Grenade04", "Grenade06", "Grenade01", "Grenade02", "Grenade07", "Grenade05", "BoomerJar07", "BoomerJar08", "BoomerJar09",
	"Defibrillator07", "Defibrillator08", "Defibrillator09", "Defibrillator10", "Defibrillator11", "Defibrillator12", "Defibrillator13", "Defibrillator14", "Defibrillator16", "Defibrillator17", "Defibrillator18",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10", "NiceJob11", "NiceJob12", "NiceJob13",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04", "ToTheRescue05", "ToTheRescue06",
	"WarnCareful01", "WarnCareful02", "WarnCareful03",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04",
	"GrabbedBySmoker01", "GrabbedBySmoker02", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker02C", "GrabbedBySmoker02D", "GrabbedBySmoker02E", "GrabbedBySmoker03", "GrabbedBySmoker03A", "GrabbedBySmoker03B", "GrabbedBySmoker04", "GrabbedBySmokerC101", "GrabbedBySmokerC102", "GrabbedBySmokerC103", "GrabbedBySmokerC104"
};

static const String:g_Bill[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry07", "Sorry08", "Sorry09", "Sorry10", "Sorry11", "Sorry12",
	"Laughter01", "Laughter02", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter10", "Laughter11", "Laughter12", "Laughter13", "Laughter14", "ReactionPositive02", "ReactionPositive05", "ReactionPositive06", "ReactionPositive07", "ReactionPositive08", "ViolenceAwe06", "Taunt01", "Taunt02", "Taunt07", "Taunt08", "Taunt019",
	"GenericResponses06", "Yes02", "Yes03", "Yes04", "Yes05", "Yes06", "YouAreWelcome10",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No10", "No11", "No14", "No15", "C6DLC3SECONDSAFEROOM02",
	"AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady09",
	"ReactionNegative01", "ReactionNegative02", "ReactionNegative03", "ReactionNegative04", "ReactionNegative12", "ReactionBoomerVomit03", "Swears10",
	"Hurrah02", "Hurrah03", "Hurrah05", "Hurrah18", "Hurrah20",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks05", "Thanks06", "Thanks07", "Thanks08", "Thanks09", "Thanks10", "Thanks11",
	"ReactionPositive02", "ReactionPositive04", "ReactionPositive05", "ReactionPositive06", "ReactionPositive07", "ReactionPositive08", "ReactionPositive10", "Taunt01", "Taunt02", "Taunt07", "Taunt08", "Taunt09", "WorldHospital0210", "WorldSmallTown0411",
	"LookOut01", "LookOut02", "LookOut03", "LookOut04", "LookOut05", "LookOut06",
	"Reloading01", "Reloading02", "Reloading03",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07", "HurtMinor08", "HurtMinor09", "HurtMinor10", "HurtMinor11",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HurtMajor07", "HurtMajor08", "HurtMajor09",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial04",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06", "HurtCritical07", "HurtCritical08", "HurtCritical09", "FallShort03",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04", "IncapacitatedInjury05",
	"Dying01", "Dying02", "Dying03", "Dying04", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "Help07", "Help08", "Help09", "Help10", "Help11", "Help12", "Help13", "Help14", "Help15", "Help16", "Help17", "LedgeHangMiddle02", "LedgeHangMiddle03", "LedgeHangMiddle05", "LedgeHangStart01",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03", "PainRelieftFirstAid04",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07", "HealOther08",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "MoveOn08", "MoveOn09", "MoveOn10", "MoveOn11", "MoveOn12", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05", "FollowMe06", "FollowMe07", "FollowMe08", "FollowMe09",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05", "LeadOn06", "LeadOn07", "LeadOn08",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04", "ImWithYou05", "ImWithYou06",
	"PainReliefSigh01", "PainReliefSigh02", "PainReliefSigh03", "PainReliefSigh04",
	"YouAreWelcome01", "YouAreWelcome02", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome08", "YouAreWelcome10", "YouAreWelcome11", "YouAreWelcome12", "YouAreWelcome14", "YouAreWelcome15",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11", "GettingRevived12", "GettingRevived13",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend14", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA07", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendB15", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07", "ReviveFriendLoud08", "ReviveFriendLoud09", "ReviveFriendLoud10",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05", "ReviveCriticalFriend06", "ReviveCriticalFriend07",
	"Grenade01", "Grenade02", "Grenade03", "Grenade04", "Grenade05", "Grenade06",
	"AreaClear01", "AreaClear04",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp07", "HurryUp08", "HurryUp09",
	"NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10", "NiceJob11", "NiceJob012", "NiceJob13", "NiceJob14", "NiceJob15", "NiceJob16", "NiceJob17", "NiceJob18", "NiceJob19", "NiceJob20", "NiceJob21", "NiceJob22",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03",
	"WarnCareful01", "WarnCareful02", "WarnCareful03", "WarnCareful04", "WarnCareful05", "WarnCareful06", "WarnCareful07", "WarnCareful08", "WarnCareful09",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04",
	"GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker03"
};

static const String:g_Francis[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09", "Sorry10", "Sorry12", "Sorry13", "Sorry14", "Sorry15", "Sorry16", "Sorry17", "Sorry18", "GenericResponses11",
	"Laughter01", "Laughter02", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter11", "Laughter12", "Laughter13", "Laughter14", "DLC2GasTanks04", "HurtMajor04", "ReactionPositive01", "ViolenceAwe07", "Taunt05", "Taunt06", "Taunt07",
	"Yes01", "Yes03",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07", "No08", "No09", "No11", "No14", "No15", "No16", "No17", "No18", "DLC1_C6M1_InitialMeeting02", "DLC1_C6M1_InitialMeeting03", "DLC1_C6M1_InitialMeeting04", "DLC1_C6M1_InitialMeeting40",
	"AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady06", "AskReady07", "AskReady08", "AskReady09", "AskReady10",
	"Laughter03", "Laughter08", "Laughter10", "NegativeNoise01", "NegativeNoise02", "NegativeNoise03", "NegativeNoise04", "NegativeNoise05", "NegativeNoise06", "NegativeNoise07", "NegativeNoise08", "PositiveNoise02", "PositiveNoise05", "ReactionNegative02",
	"Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah12", "Hurrah13", "Hurrah14", "Hurrah15", "Hurrah21", "Hurrah22", "Hurrah23", "Hurrah24",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks07", "Thanks08", "Thanks09", "Thanks10", "Thanks12", "Thanks15",
	"Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah11", "Hurrah16", "Hurrah17", "Hurrah18", "Hurrah19", "Hurrah20", "ReactionPositive03", "ReactionPositive06", "ReactionPositive08", "ReactionPositive09", "ReactionPositive10", "ReactionPositive11", "Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt06", "Taunt07", "Taunt08", "Taunt09", "Taunt10",
	"LookOut01", "LookOut02", "LookOut03", "LookOut04", "LookOut05", "LookOut06",
	"Reloading01", "Reloading02", "Reloading03",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07", "HurtMinor08",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HurtMajor07", "HurtMajor08", "HurtMajor09", "HurtMajor10", "HurtMajor11",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06", "HurtCritical07", "HurtCritical08", "HurtCritical09", "HurtCritical10", "HurtCritical11",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04", "IncapacitatedInjury05", "IncapacitatedInjury06",
	"Dying01", "Dying02", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "Help07", "Help08", "Help09", "Help10", "Help11", "Help12", "Help13", "Help14", "Help15", "LedgeHangMiddle04", "LedgeHangStart01", "LedgeHangStart02", "LedgeHangStart03", "LedgeHangStart04", "LedgeHangStart05", "LedgeHangStart08", "LedgeHangStart09",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08", "CoverMe09", "CoverMe10", "CoverMe11", "CoverMe12", "CoverMe13", "CoverMe14",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid05",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "MoveOn08", "MoveOn09", "MoveOn10", "MoveOn11", "MoveOn12", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05", "FollowMe06", "FollowMe07", "FollowMe09",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05", "LeadOn06", "LeadOn07",
	"ImWithYou01", "ImWithYou02", "ImWithYou03", "ImWithYou04", "ImWithYou05", "ImWithYou06", "ImWithYou07", "ImWithYou08", "ImWithYou09", "ImWithYou10",
	"PainReliefSigh01", "PainReliefSigh02", "PainReliefSigh03", "PainReliefSigh04", "PainReliefSigh05",
	"YouAreWelcome02", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome06", "YouAreWelcome07", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome10", "YouAreWelcome11", "YouAreWelcome12", "YouAreWelcome13", "YouAreWelcome14",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived13", "GettingRevived14", "GettingRevived15", "GettingRevived16",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA07", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07", "ReviveFriendLoud08", "ReviveFriendLoud09", "ReviveFriendLoud10", "ReviveFriendLoud11", "ReviveFriendLoud12",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05", "ReviveCriticalFriend06", "ReviveCriticalFriend07", "ReviveCriticalFriend08",
	"Grenade01", "Grenade02", "Grenade03", "Grenade04", "Grenade05", "Grenade06",
	"AreaClear01", "AreaClear05",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp08", "HurryUp09",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob09", "NiceJob10", "NiceJob11", "NiceJob12", "NiceJob13", "NiceJob14", "NiceJob15", "NiceJob16", "NiceJob17", "NiceJob18", "NiceJob19",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04", "ToTheRescue05", "ToTheRescue06", "ToTheRescue07", "ToTheRescue08",
	"WarnCareful01", "WarnCareful02", "WarnCareful03", "WarnCareful04", "WarnCareful05", "WarnCareful06", "WarnCareful07", "WarnCareful08", "WarnCareful09",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04", "WaitHere05", "WaitHere06", "WaitHere07", "WaitHere08",
	"GrabbedBySmoker01A", "GrabbedBySmoker02A", "GrabbedBySmoker03"
};

static const String:g_Louis[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry07",
	"Laughter01", "Laughter02", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter11", "Laughter12", "Laughter13", "Laughter14", "Laughter15", "Laughter16", "Laughter17", "Laughter18", "Laughter19", "Laughter20", "Laughter21", "PositiveNoise02", "Taunt07", "Taunt08", "Taunt09", "Taunt10",
	"Yes02", "Yes08",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08",
	"AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady06", "AskReady07", "AskReady09",
	"NegativeNoise01", "NegativeNoise02", "NegativeNoise03", "PlayerTransitionClose01", "PositiveNoise04", "ReactionNegative01", "ReactionNegative04",
	"Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "Hurrah12", "Hurrah13", "Hurrah16", "PositiveNoise02", "PositiveNoise03", "PositiveNoise04", "ReactionPositive10", "ZombieGenericShort14",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks07", "Thanks08", "Thanks09", "Thanks10", "Thanks11",
	"GenericResponses40", "Hurrah01", "Hurrah02", "Hurrah03", "Hurrah14", "Hurrah15", "ReactionPositive05", "ReactionPositive06", "ReactionPositive07", "ReactionPositive09", "Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt06", "Taunt07", "Taunt08", "Taunt09", "Taunt10",
	"LookOut01", "LookOut02", "LookOut03", "LookOut04", "LookOut05", "LookOut06",
	"Reloading01", "Reloading02", "Reloading03",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07", "HurtMinor08",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HurtMajor07", "HurtMajor08", "HurtMajor09", "HurtMajor10",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial04", "IncapacitatedInitial05",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03",
	"Dying01", "Dying02", "Dying03", "Dying04", "Help01", "Help02", "Help03", "Help04", "Help05", "Help06", "Help07", "Help08", "Help09", "Help10", "Help11",
	"CoverMe01", "CoverMe02", "CoverMe03", "CoverMe04", "CoverMe05", "CoverMe06", "CoverMe07", "CoverMe08", "CoverMe09", "CoverMe10",
	"PainRelieftFirstAid01", "PainRelieftFirstAid03", "PainRelieftFirstAid05",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "MoveOn08", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe04", "FollowMe05",
	"LeadOn01", "LeadOn02", "LeadOn03", "LeadOn04", "LeadOn05",
	"ImWithYou01", "ImWithYou02", "ImWithYou03",
	"PainReliefSigh01", "PainReliefSigh02", "PainReliefSigh03", "PainReliefSigh04", "PainReliefSigh05",
	"YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome07", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome10", "YouAreWelcome13", "YouAreWelcome14", "YouAreWelcome15", "YouAreWelcome16", "YouAreWelcome17",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11",
	"ReviveFriend01", "ReviveFriend02", "ReviveFriend03", "ReviveFriend04", "ReviveFriend05", "ReviveFriend06", "ReviveFriend07", "ReviveFriend08", "ReviveFriend09", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend18", "ReviveFriend19", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA07", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB13", "ReviveFriendB14", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07", "ReviveFriendLoud08", "ReviveFriendLoud09", "ReviveFriendLoud10", "ReviveFriendLoud11",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05",
	"Grenade01", "Grenade02", "Grenade03", "Grenade04", "Grenade05", "Grenade06", "Grenade07",
	"AreaClear01",
	"HurryUp01", "HurryUp02", "HurryUp03", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp07", "HurryUp08", "HurryUp09", "HurryUp10", "HurryUp11", "HurryUp12", "HurryUp13",
	"NiceJob01", "NiceJob02", "NiceJob03", "NiceJob04", "NiceJob05", "NiceJob06", "NiceJob07",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03",
	"WarnCareful01", "WarnCareful02", "WarnCareful03", "WarnCareful04", "WarnCareful05", "WarnCareful06", "WarnCareful07", "WarnCareful08", "WarnCareful09", "WarnCareful10", "WarnCareful11",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04", "WaitHere05",
	"GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker03A", "GrabbedBySmoker03B", "GrabbedBySmoker04"
};

static const String:g_Zoey[][] =
{
	"Sorry11", "Sorry12", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09", "Sorry10", "Sorry13", "Sorry14", "Sorry15", "Sorry16", "Sorry17", "Sorry18", "Sorry20", "Sorry23", "DLC1_C6M3_FinaleChat02",
	"Laughter11", "Laughter12", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter10", "Laughter13", "Laughter01", "Laughter02", "Laughter03", "Laughter14", "Laughter15", "Laughter16", "Laughter17", "Laughter18", "Laughter19", "Laughter20", "PositiveNoise02", "Laughter21", "DLC2GasTanks03",
	"Yes01", "Yes02", "Yes03", "Yes04", "Yes05", "Yes06", "Yes07", "Yes08", "Yes09", "Yes10", "Yes13", "Yes14", "Yes15", "Yes16", "Yes17", "Yes18", "GenericResponses04",
	"NegativeNoise09", "Uncertain12", "DLC1_C6M1_InitialMeeting25", "DLC1_C6M1_InitialMeeting27", "DLC1_C6M1_InitialMeeting28", "DLC1_C6M1_InitialMeeting29", "No01", "No07", "No08", "No09", "No10", "No11", "No14", "No15", "No18", "No21", "No22", "No23", "No24", "No25", "No31", "No36", "No38", "No43", "No48", "No49", "NegativeNoise02",
	"AskReady03", "AskReady11", "AskReady12", "AskReady13", "AskReady14", "AskReady15", "AskReady17", "AskReady18", "AskReady19", "AskReady21",
	"NegativeNoise01", "NegativeNoise04", "NegativeNoise05", "NegativeNoise06", "NegativeNoise07", "NegativeNoise08", "NegativeNoise10", "NegativeNoise14", "NegativeNoise15", "ReactionNegative01", "ReactionNegative03", "ReactionNegative04", "ReactionNegative23", "ReactionNegative26",
	"Hurrah07", "Hurrah10", "Hurrah13", "Hurrah18", "Hurrah19", "Hurrah20", "Hurrah23", "Hurrah31", "Hurrah35", "Hurrah38", "Hurrah46", "Hurrah48", "Hurrah53", "Hurrah54", "Hurrah55", "Hurrah58",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks06", "Thanks07", "Thanks08", "Thanks09", "Thanks13", "Thanks19", "Thanks20", "Thanks23", "Thanks24", "Thanks25", "Thanks27", "Thanks28", "Thanks30", "ReactionPositive12", "ReactionPositive27",
	"GenericResponses37", "Hurrah01", "Hurrah03", "Hurrah04", "Hurrah08", "Hurrah11", "Hurrah12", "Hurrah16", "Hurrah17", "Hurrah22", "Hurrah34", "Hurrah51", "Hurrah52", "Hurrah56", "Hurrah57", "ReactionPositive01", "ReactionPositive02", "ReactionPositive13", "ReactionPositive14", "Taunt02", "Taunt13", "Taunt18", "Taunt19", "Taunt20", "Taunt21", "Taunt24", "Taunt25", "Taunt26", "Taunt28", "Taunt29", "Taunt30", "Taunt31", "Taunt34", "Taunt35", "Taunt39",
	"LookOut01", "LookOut03", "LookOut08", "DLC1_C6M3_L4D11stSpot04", "DLC1_C6M3_L4D11stSpot02", "DLC1_C6M3_L4D11stSpot03", "DLC1_C6M3_L4D11stSpot05", "DLC1_C6M3_L4D11stSpot06",
	"Reloading01", "Reloading02", "Reloading03", "Reloading04",
	"HurtMinor01", "HurtMinor02", "HurtMinor03", "HurtMinor04", "HurtMinor05", "HurtMinor06", "HurtMinor07", "HurtMinor08", "ReactionNegativeSpecial01", "ReactionNegativeSpecial03", "ReactionNegativeSpecial06", "ReactionNegativeSpecial12", "ReactionNegativeSpecial13",
	"HurtMajor01", "HurtMajor02", "HurtMajor03", "HurtMajor04", "HurtMajor05", "HurtMajor06", "HordeAttack04", "HordeAttack05", "HordeAttack10", "HordeAttack13", "HordeAttack17", "HordeAttack18", "HordeAttack21", "HordeAttack22", "HordeAttack25", "HordeAttack28", "HordeAttack29", "HordeAttack30",
	"IncapacitatedInitial01", "IncapacitatedInitial02", "IncapacitatedInitial03", "IncapacitatedInitial05",
	"HurtCritical01", "HurtCritical02", "HurtCritical03", "HurtCritical04", "HurtCritical05", "HurtCritical06", "HurtCritical07", "NegativeNoise13",
	"IncapacitatedInjury01", "IncapacitatedInjury02", "IncapacitatedInjury03", "IncapacitatedInjury04",
	"Dying01", "Dying02", "Dying03", "Dying04", "Dying05", "Help01", "Help02", "Help03", "Help04", "Help07", "Help08", "Help12", "Help13", "Help14", "Help15", "Help16", "Help17", "LedgeHangEnd02", "LedgeHangEnd06", "LedgeHangEnd17", "LedgeHangEnd21", "LedgeHangMiddle09", "LedgeHangStart03", "LedgeHangStart04", "LedgeHangStart05", "LedgeHangStart06", "LedgeHangStart10",
	"CoverMe02", "CoverMe05", "CoverMe06", "CoverMe10", "CoverMe14", "CoverMe18", "CoverMe19", "CoverMe20", "CoverMe21", "CoverMe23", "CoverMe25", "CoverMe27",
	"PainRelieftFirstAid01", "PainRelieftFirstAid02", "PainRelieftFirstAid03",
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOtherCombat07", "HealOtherCombat08", "HealOtherCombat09", "HealOtherCombat10", "HealOtherCombat11",
	"MoveOn01", "MoveOn02", "MoveOn03", "MoveOn04", "MoveOn05", "MoveOn06", "MoveOn07", "MoveOn08", "MoveOn09", "MoveOn10", "MoveOn11", "MoveOn12", "MoveOn13", "FollowMe01", "FollowMe02", "FollowMe03", "FollowMe05", "FollowMe07", "FollowMe10", "FollowMe11", "FollowMe12", "FollowMe14", "FollowMe15", "FollowMe16", "FollowMe17", "FollowMe18", "FollowMe20", "FollowMe22", "FollowMe23", "FollowMe24", "FollowMe25", "FollowMe27", "FollowMe28",
	"LeadOn04", "LeadOn06", "LeadOn07", "LeadOn08", "LeadOn09", "LeadOn10", "LeadOn12", "LeadOn13", "LeadOn16", "LeadOn22", "LeadOn24", "LeadOn25", "LeadOn26", "LeadOn27", "LeadOn28",
	"ImWithYou10", "ImWithYou11", "ImWithYou12", "ImWithYou15", "ImWithYou16", "ImWithYou17", "ImWithYou18", "ImWithYou19", "ImWithYou20", "ImWithYou21", "ImWithYou22", "ImWithYou26", "ImWithYou27", "ImWithYou31", "ImWithYou32", "ImWithYou37", "ImWithYou38",
	"PainReliefSigh01", "PainReliefSigh02", "PainReliefSigh08", "PainReliefSigh10", "PainReliefSigh11",
	"YouAreWelcome03", "YouAreWelcome04", "YouAreWelcome05", "YouAreWelcome06", "YouAreWelcome08", "YouAreWelcome09", "YouAreWelcome11", "YouAreWelcome12", "YouAreWelcome13", "YouAreWelcome14", "YouAreWelcome15", "YouAreWelcome16", "YouAreWelcome17", "YouAreWelcome18", "YouAreWelcome20", "YouAreWelcome21", "YouAreWelcome23", "YouAreWelcome25", "YouAreWelcome26", "YouAreWelcome30", "YouAreWelcome32", "YouAreWelcome36", "YouAreWelcome39",
	"GettingRevived01", "GettingRevived02", "GettingRevived03", "GettingRevived04", "GettingRevived05", "GettingRevived06", "GettingRevived07", "GettingRevived08", "GettingRevived09", "GettingRevived10", "GettingRevived11",
	"ReviveFriend01", "ReviveFriend03", "ReviveFriend04", "ReviveFriend06", "ReviveFriend08", "ReviveFriend10", "ReviveFriend11", "ReviveFriend12", "ReviveFriend16", "ReviveFriend17", "ReviveFriend19", "ReviveFriend25", "ReviveFriend31", "ReviveFriendA01", "ReviveFriendA02", "ReviveFriendA03", "ReviveFriendA04", "ReviveFriendA05", "ReviveFriendA06", "ReviveFriendA08", "ReviveFriendB01", "ReviveFriendB02", "ReviveFriendB03", "ReviveFriendB04", "ReviveFriendB05", "ReviveFriendB06", "ReviveFriendB07", "ReviveFriendB08", "ReviveFriendB09", "ReviveFriendB10", "ReviveFriendB11", "ReviveFriendB12", "ReviveFriendB14", "ReviveFriendB15", "ReviveFriendB16", "ReviveFriendB17", "ReviveFriendLoud01", "ReviveFriendLoud02", "ReviveFriendLoud03", "ReviveFriendLoud04", "ReviveFriendLoud05", "ReviveFriendLoud06", "ReviveFriendLoud07", "ReviveFriendLoud08", "ReviveFriendLoud09", "ReviveFriendLoud10", "ReviveFriendLoud11", "ReviveFriendLoud12", "ReviveFriendLoud13",
	"ReviveCriticalFriend01", "ReviveCriticalFriend02", "ReviveCriticalFriend03", "ReviveCriticalFriend04", "ReviveCriticalFriend05", "ReviveCriticalFriend06", "ReviveCriticalFriend07",
	"Grenade02", "Grenade04", "Grenade09", "Grenade10", "Grenade12", "Grenade13",
	"AreaClear01", "AreaClear04",
	"HurryUp01", "HurryUp04", "HurryUp05", "HurryUp06", "HurryUp08", "HurryUp09",
	"NiceJob01", "NiceJob02", "NiceJob05", "NiceJob06", "NiceJob07", "NiceJob08", "NiceJob11", "NiceJob17", "NiceJob18", "NiceJob20", "NiceJob21", "NiceJob22", "NiceJob23", "NiceJob26", "NiceJob29", "NiceJob33", "NiceJob36", "NiceJob38", "NiceJob42", "NiceJob43", "NiceJob44", "NiceJob48", "NiceJob51", "NiceJob52", "NiceJob54", "NiceJob56", "NiceJob57", "NiceJob58", "NiceJob59", "NiceJob60", "NiceJob61",
	"ToTheRescue01", "ToTheRescue02", "ToTheRescue03", "ToTheRescue04", "ToTheRescue06", "ToTheRescue07", "ToTheRescue08", "ToTheRescue09",
	"WarnCareful04", "WarnCareful07", "WarnCareful09", "WarnCareful13", "WarnCareful17", "WarnCareful18", "WarnCareful20",
	"WaitHere01", "WaitHere02", "WaitHere03", "WaitHere04", "WaitHere05", "WaitHere06",
	"GrabbedBySmoker01A", "GrabbedBySmoker01B", "GrabbedBySmoker01C", "GrabbedBySmoker02A", "GrabbedBySmoker02B", "GrabbedBySmoker02C", "GrabbedBySmoker03A", "GrabbedBySmoker03B", "GrabbedBySmoker03C", "GrabbedBySmoker04A", "GrabbedBySmoker04B"
};

static bool:IsAlreadyIncapacitated[MAXPLAYERS+1] = false;
static bool:IsReviving[MAXPLAYERS+1] = false;
static bool:HasRevived[MAXPLAYERS+1] = false;
static bool:AlreadyCalledForHelp[MAXPLAYERS+1] = false;
static bool:AlreadyHurt[MAXPLAYERS+1] = false;

static bool:IsGrabbedBySI[MAXPLAYERS+1] = false;

public OnPluginStart() 
{
	HookEvent("round_start", OnVocalizationsReset);
	HookEvent("round_end", OnVocalizationsReset);
	HookEvent("mission_lost", OnVocalizationsReset);
	HookEvent("map_transition", OnVocalizationsReset);
	HookEvent("player_spawn", OnVocalizationsReset);
	HookEvent("player_transitioned", OnVocalizationsReset);
	HookEvent("weapon_reload", OnWeaponReload);
	HookEvent("heal_begin", OnHealBegin);
	HookEvent("heal_success", OnHealSuccess);
	HookEvent("pills_used", OnSupplyUsed);
	HookEvent("adrenaline_used", OnSupplyUsed);
	HookEvent("revive_begin", OnReviveBegin);
	HookEvent("revive_end", OnReviveEnd);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	HookEvent("player_ledge_grab", OnPlayerLedgeGrab);
	HookEvent("defibrillator_begin", OnDefibrillatorBegin);
	HookEvent("defibrillator_used", OnDefibrillatorUsed);
	HookEvent("tongue_grab", OnTongueGrab);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("charger_pummel_start", OnGrabbedByInfected);
	HookEvent("jockey_ride", OnGrabbedByInfected);
	HookEvent("lunge_pounce", OnGrabbedByInfected);
	HookEvent("tongue_pull_stopped", OnInfectedDead);
	HookEvent("tongue_release", OnInfectedDead);
	HookEvent("charger_pummel_end", OnInfectedDead);
	HookEvent("jockey_ride_end", OnInfectedDead);
	HookEvent("pounce_end", OnInfectedDead);
	HookEvent("pounce_stopped", OnInfectedDead);
}

public OnMapStart()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			IsAlreadyIncapacitated[i] = false;
			IsReviving[i] = false;
			HasRevived[i] = false;
			AlreadyCalledForHelp[i] = false;
			AlreadyHurt[i] = false;
			
			IsGrabbedBySI[i] = false;
		}
	}
}

public OnMapEnd()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			IsAlreadyIncapacitated[i] = false;
			IsReviving[i] = false;
			HasRevived[i] = false;
			AlreadyCalledForHelp[i] = false;
			AlreadyHurt[i] = false;
			
			IsGrabbedBySI[i] = false;
		}
	}
}

public Action:OnVocalizationsReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
	{
		IsAlreadyIncapacitated[client] = false;
		IsReviving[client] = false;
		HasRevived[client] = false;
		AlreadyCalledForHelp[client] = false;
		AlreadyHurt[client] = false;
		
		IsGrabbedBySI[client] = false;
	}
}

public Action:L4D_OnClientVocalize(client, const String:vocalize[]) 
{
	if(!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	if (StrEqual(vocalize, "playersorry"))
	{ 
		switch (i_Type)
		{
			case 1: {i_Min = 0; i_Max = 6;}
			case 2: {i_Min = 0; i_Max = 7;}
			case 3: {i_Min = 0; i_Max = 9;}
			case 4: {i_Min = 0; i_Max = 8;}
			case 5: {i_Min = 0; i_Max = 10;}
			case 6: {i_Min = 0; i_Max = 17;}
			case 7: {i_Min = 0; i_Max = 5;}
			case 8: {i_Min = 0; i_Max = 17;}
		}
	}
	else if(StrEqual(vocalize, "playerlaugh"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 7; i_Max = 13;}
			case 2: {i_Min = 8; i_Max = 13;}
			case 3: {i_Min = 10; i_Max = 19;}
			case 4: {i_Min = 9; i_Max = 14;}
			case 5: {i_Min = 11; i_Max = 34;}
			case 6: {i_Min = 18; i_Max = 36;}
			case 7: {i_Min = 6; i_Max = 29;}
			case 8: {i_Min = 18; i_Max = 40;}
		}
	}
	else if(StrEqual(vocalize, "playeryes"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 14; i_Max = 17;}
			case 2: {i_Min = 14; i_Max = 17;}
			case 3: {i_Min = 20; i_Max = 22;}
			case 4: {i_Min = 15; i_Max = 18;}
			case 5: {i_Min = 35; i_Max = 41;}
			case 6: {i_Min = 37; i_Max = 38;}
			case 7: {i_Min = 30; i_Max = 31;}
			case 8: {i_Min = 41; i_Max = 57;}
		}
	}
	else if(StrEqual(vocalize, "playerno"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 18; i_Max = 34;}
			case 2: {i_Min = 18; i_Max = 30;}
			case 3: {i_Min = 23; i_Max = 34;}
			case 4: {i_Min = 19; i_Max = 33;}
			case 5: {i_Min = 42; i_Max = 55;}
			case 6: {i_Min = 39; i_Max = 57;}
			case 7: {i_Min = 32; i_Max = 39;}
			case 8: {i_Min = 58; i_Max = 84;}
		}
	}
	else if(StrEqual(vocalize, "playeraskready"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 35; i_Max = 43;}
			case 2: {i_Min = 31; i_Max = 43;}
			case 3: {i_Min = 35; i_Max = 37;}
			case 4: {i_Min = 34; i_Max = 36;}
			case 5: {i_Min = 56; i_Max = 61;}
			case 6: {i_Min = 58; i_Max = 67;}
			case 7: {i_Min = 40; i_Max = 47;}
			case 8: {i_Min = 85; i_Max = 94;}
		}
	}
	else if(StrEqual(vocalize, "playernegative") || StrEqual(vocalize, "playerswear"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 44; i_Max = 57;}
			case 2: {i_Min = 44; i_Max = 66;}
			case 3: {i_Min = 38; i_Max = 50;}
			case 4: {i_Min = 37; i_Max = 51;}
			case 5: {i_Min = 62; i_Max = 68;}
			case 6: {i_Min = 68; i_Max = 81;}
			case 7: {i_Min = 48; i_Max = 54;}
			case 8: {i_Min = 95; i_Max = 108;}
		}
	}
	else if(StrEqual(vocalize, "playerhurrah"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 58; i_Max = 86;}
			case 2: {i_Min = 67; i_Max = 79;}
			case 3: {i_Min = 51; i_Max = 71;}
			case 4: {i_Min = 52; i_Max = 69;}
			case 5: {i_Min = 69; i_Max = 73;}
			case 6: {i_Min = 82; i_Max = 95;}
			case 7: {i_Min = 55; i_Max = 69;}
			case 8: {i_Min = 109; i_Max = 124;}
		}
	}
	else if(StrEqual(vocalize, "playerthanks"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 87; i_Max = 92;}
			case 2: {i_Min = 80; i_Max = 82;}
			case 3: {i_Min = 72; i_Max = 74;}
			case 4: {i_Min = 70; i_Max = 76;}
			case 5: {i_Min = 74; i_Max = 84;}
			case 6: {i_Min = 96; i_Max = 105;}
			case 7: {i_Min = 70; i_Max = 78;}
			case 8: {i_Min = 125; i_Max = 143;}
		}
	}
	else if(StrEqual(vocalize, "playertaunt") || StrEqual(vocalize, "survivortaunt"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 93; i_Max = 105;}
			case 2: {i_Min = 83; i_Max = 91;}
			case 3: {i_Min = 75; i_Max = 85;}
			case 4: {i_Min = 77; i_Max = 82;}
			case 5: {i_Min = 85; i_Max = 98;}
			case 6: {i_Min = 106; i_Max = 131;}
			case 7: {i_Min = 79; i_Max = 98;}
			case 8: {i_Min = 144; i_Max = 178;}
		}
	}
	else if(StrEqual(vocalize, "playerlookout") || StrEqual(vocalize, "survivorvocalizelookout") || StrEqual(vocalize,"survivorlookout"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 106; i_Max = 109;}
			case 2: {i_Min = 92; i_Max = 94;}
			case 3: {i_Min = 86; i_Max = 88;}
			case 4: {i_Min = 83; i_Max = 85;}
			case 5: {i_Min = 99; i_Max = 104;}
			case 6: {i_Min = 132; i_Max = 137;}
			case 7: {i_Min = 99; i_Max = 104;}
			case 8: {i_Min = 179; i_Max = 186;}
		}
	}
	else if(StrEqual(vocalize, "playerreload") || StrEqual(vocalize, "reloading") || StrEqual(vocalize, "playerreloading"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 110; i_Max = 116;}
			case 2: {i_Min = 95; i_Max = 101;}
			case 3: {i_Min = 89; i_Max = 94;}
			case 4: {i_Min = 86; i_Max = 89;}
			case 5: {i_Min = 105; i_Max = 107;}
			case 6: {i_Min = 138; i_Max = 140;}
			case 7: {i_Min = 105; i_Max = 107;}
			case 8: {i_Min = 187; i_Max = 190;}
		}
	}
	else if(StrEqual(vocalize, "playerminorhurt") || StrEqual(vocalize, "playerhurtminor"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 117; i_Max = 123;}
			case 2: {i_Min = 102; i_Max = 108;}
			case 3: {i_Min = 95; i_Max = 103;}
			case 4: {i_Min = 90; i_Max = 95;}
			case 5: {i_Min = 108; i_Max = 118;}
			case 6: {i_Min = 141; i_Max = 148;}
			case 7: {i_Min = 108; i_Max = 115;}
			case 8: {i_Min = 191; i_Max = 203;}
		}
	}
	else if(StrEqual(vocalize, "playermajorhurt") || StrEqual(vocalize, "playerhurtmajor"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 124; i_Max = 134;}
			case 2: {i_Min = 109; i_Max = 119;}
			case 3: {i_Min = 104; i_Max = 109;}
			case 4: {i_Min = 96; i_Max = 99;}
			case 5: {i_Min = 119; i_Max = 127;}
			case 6: {i_Min = 149; i_Max = 159;}
			case 7: {i_Min = 116; i_Max = 125;}
			case 8: {i_Min = 204; i_Max = 221;}
		}
	}
	else if(StrEqual(vocalize, "playerincapacitatedinitial") || StrEqual(vocalize, "playerincapacitated"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 135; i_Max = 138;}
			case 2: {i_Min = 120; i_Max = 123;}
			case 3: {i_Min = 110; i_Max = 112;}
			case 4: {i_Min = 100; i_Max = 103;}
			case 5: {i_Min = 128; i_Max = 131;}
			case 6: {i_Min = 160; i_Max = 162;}
			case 7: {i_Min = 126; i_Max = 130;}
			case 8: {i_Min = 222; i_Max = 225;}
		}
	}
	else if(StrEqual(vocalize, "playercriticalhurt") || StrEqual(vocalize, "playerhurtcritical"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 139; i_Max = 146;}
			case 2: {i_Min = 124; i_Max = 130;}
			case 3: {i_Min = 113; i_Max = 118;}
			case 4: {i_Min = 104; i_Max = 107;}
			case 5: {i_Min = 132; i_Max = 141;}
			case 6: {i_Min = 163; i_Max = 173;}
			case 7: {i_Min = 131; i_Max = 135;}
			case 8: {i_Min = 226; i_Max = 233;}
		}
	}
	else if(StrEqual(vocalize, "survivorincapacitatedhurt") || StrEqual(vocalize, "incapacitatedhurt"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 147; i_Max = 150;}
			case 2: {i_Min = 131; i_Max = 134;}
			case 3: {i_Min = 119; i_Max = 124;}
			case 4: {i_Min = 108; i_Max = 111;}
			case 5: {i_Min = 142; i_Max = 146;}
			case 6: {i_Min = 174; i_Max = 179;}
			case 7: {i_Min = 136; i_Max = 138;}
			case 8: {i_Min = 234; i_Max = 237;}
		}
	}
	else if(StrEqual(vocalize, "playerhelp") || StrEqual(vocalize, "helpincapped") || StrEqual(vocalize, "playerhelpincapped") || StrEqual(vocalize, "playerhelpincapacitated"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 151; i_Max = 166;}
			case 2: {i_Min = 135; i_Max = 149;}
			case 3: {i_Min = 125; i_Max = 147;}
			case 4: {i_Min = 112; i_Max = 126;}
			case 5: {i_Min = 147; i_Max = 171;}
			case 6: {i_Min = 180; i_Max = 204;}
			case 7: {i_Min = 139; i_Max = 152;}
			case 8: {i_Min = 238; i_Max = 264;}
		}
	}
	else if(StrEqual(vocalize, "playerhealing") || StrEqual(vocalize, "covermeheal"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 167; i_Max = 178;}
			case 2: {i_Min = 150; i_Max = 163;}
			case 3: {i_Min = 148; i_Max = 157;}
			case 4: {i_Min = 127; i_Max = 133;}
			case 5: {i_Min = 172; i_Max = 179;}
			case 6: {i_Min = 205; i_Max = 218;}
			case 7: {i_Min = 153; i_Max = 162;}
			case 8: {i_Min = 265; i_Max = 276;}
		}
	}
	else if(StrEqual(vocalize, "relaxedsigh"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 179; i_Max = 182;}
			case 2: {i_Min = 164; i_Max = 170;}
			case 3: {i_Min = 158; i_Max = 163;}
			case 4: {i_Min = 134; i_Max = 138;}
			case 5: {i_Min = 180; i_Max = 183;}
			case 6: {i_Min = 219; i_Max = 221;}
			case 7: {i_Min = 163; i_Max = 165;}
			case 8: {i_Min = 277; i_Max = 279;}
		}
	}
	else if(StrEqual(vocalize, "healother"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 183; i_Max = 189;}
			case 2: {i_Min = 171; i_Max = 180;}
			case 3: {i_Min = 164; i_Max = 175;}
			case 4: {i_Min = 139; i_Max = 142;}
			case 5: {i_Min = 184; i_Max = 191;}
			case 6: {i_Min = 222; i_Max = 228;}
			case 7: {i_Min = 166; i_Max = 170;}
			case 8: {i_Min = 280; i_Max = 289;}
		}
	}
	else if (StrEqual(vocalize, "playermoveon"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 190; i_Max = 205;}
			case 2: {i_Min = 181; i_Max = 197;}
			case 3: {i_Min = 176; i_Max = 186;}
			case 4: {i_Min = 143; i_Max = 152;}
			case 5: {i_Min = 192; i_Max = 212;}
			case 6:
			{
				i_Min = 229;
				i_Max = 248;
			}
			case 7: {i_Min = 171; i_Max = 183;}
			case 8:
			{
				i_Min = 290;
				i_Max = 322;
			}
		}
	}
	else if (StrEqual(vocalize, "playerleadon"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 206; i_Max = 209;}
			case 2: {i_Min = 198; i_Max = 206;}
			case 3: {i_Min = 187; i_Max = 191;}
			case 4: {i_Min = 153; i_Max = 162;}
			case 5: {i_Min = 213; i_Max = 220;}
			case 6:
			{
				i_Min = 249;
				i_Max = 255;
			}
			case 7: {i_Min = 184; i_Max = 188;}
			case 8:
			{
				i_Min = 323;
				i_Max = 337;
			}
		}
	}
	else if (StrEqual(vocalize, "playerimwithyou"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 210; i_Max = 215;}
			case 2: {i_Min = 207; i_Max = 211;}
			case 3: {i_Min = 192; i_Max = 195;}
			case 4: {i_Min = 165; i_Max = 170;}
			case 5: {i_Min = 221; i_Max = 226;}
			case 6:
			{
				i_Min = 256;
				i_Max = 265;
			}
			case 7: {i_Min = 189; i_Max = 191;}
			case 8:
			{
				i_Min = 338;
				i_Max = 354;
			}
		}
	}
	else if (StrEqual(vocalize, "relievedsigh"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 216; i_Max = 221;}
			case 2: {i_Min = 212; i_Max = 216;}
			case 3: {i_Min = 196; i_Max = 203;}
			case 4: {i_Min = 171; i_Max = 175;}
			case 5: {i_Min = 227; i_Max = 230;}
			case 6:
			{
				i_Min = 266;
				i_Max = 270;
			}
			case 7: {i_Min = 192; i_Max = 196;}
			case 8:
			{
				i_Min = 355;
				i_Max = 359;
			}
		}
	}
	else if (StrEqual(vocalize, "playeryouarewelcome"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 222; i_Max = 226;}
			case 2: {i_Min = 217; i_Max = 233;}
			case 3: {i_Min = 204; i_Max = 213;}
			case 4: {i_Min = 176; i_Max = 185;}
			case 5: {i_Min = 231; i_Max = 240;}
			case 6:
			{
				i_Min = 271;
				i_Max = 282;
			}
			case 7: {i_Min = 197; i_Max = 208;}
			case 8:
			{
				i_Min = 360;
				i_Max = 382;
			}
		}
	}
	else if (StrEqual(vocalize, "playergettingrevived"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 227; i_Max = 263;}
			case 2: {i_Min = 234; i_Max = 253;}
			case 3: {i_Min = 214; i_Max = 238;}
			case 4: {i_Min = 186; i_Max = 208;}
			case 5: {i_Min = 241; i_Max = 253;}
			case 6:
			{
				i_Min = 283;
				i_Max = 296;
			}
			case 7: {i_Min = 209; i_Max = 219;}
			case 8:
			{
				i_Min = 383;
				i_Max = 393;
			}
		}
	}
	else if (StrEqual(vocalize, "playerrevivefriend"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 264; i_Max = 315;}
			case 2: {i_Min = 254; i_Max = 311;}
			case 3: {i_Min = 239; i_Max = 284;}
			case 4: {i_Min = 209; i_Max = 265;}
			case 5: {i_Min = 254; i_Max = 298;}
			case 6:
			{
				i_Min = 297;
				i_Max = 335;
			}
			case 7: {i_Min = 220; i_Max = 264;}
			case 8:
			{
				i_Min = 394;
				i_Max = 442;
			}
		}
	}
	else if (StrEqual(vocalize, "playerrevivecriticalfriend"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 316; i_Max = 322;}
			case 2: {i_Min = 312; i_Max = 314;}
			case 3: {i_Min = 285; i_Max = 287;}
			case 4: {i_Min = 266; i_Max = 270;}
			case 5: {i_Min = 299; i_Max = 305;}
			case 6:
			{
				i_Min = 336;
				i_Max = 342;
			}
			case 7: {i_Min = 265; i_Max = 269;}
			case 8:
			{
				i_Min = 443;
				i_Max = 449;
			}
		}
	}
	else if (StrEqual(vocalize, "playergrenade"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 323; i_Max = 337;}
			case 2: {i_Min = 315; i_Max = 330;}
			case 3: {i_Min = 288; i_Max = 304;}
			case 4: {i_Min = 271; i_Max = 280;}
			case 5: {i_Min = 306; i_Max = 311;}
			case 6:
			{
				i_Min = 343;
				i_Max = 348;
			}
			case 7: {i_Min = 270; i_Max = 276;}
			case 8:
			{
				i_Min = 450;
				i_Max = 455;
			}
		}
	}
	else if (StrEqual(vocalize, "playerusingdefibrillator") || StrEqual(vocalize, "playerareaclear"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 338; i_Max = 352;}
			case 2: {i_Min = 331; i_Max = 343;}
			case 3: {i_Min = 305; i_Max = 317;}
			case 4: {i_Min = 281; i_Max = 292;}
			case 5: {i_Min = 312; i_Max = 313;}
			case 6:
			{
				i_Min = 349;
				i_Max = 350;
			}
			case 7: {i_Min = 277; i_Max = 277;}
			case 8:
			{
				i_Min = 456;
				i_Max = 457;
			}
		}
	}
	else if (StrEqual(vocalize, "playerhurryup"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 353; i_Max = 363;}
			case 2: {i_Min = 344; i_Max = 348;}
			case 3: {i_Min = 318; i_Max = 324;}
			case 4: {i_Min = 293; i_Max = 296;}
			case 5: {i_Min = 314; i_Max = 322;}
			case 6:
			{
				i_Min = 351;
				i_Max = 357;
			}
			case 7: {i_Min = 278; i_Max = 290;}
			case 8:
			{
				i_Min = 458;
				i_Max = 463;
			}
		}
	}
	else if (StrEqual(vocalize, "playernicejob"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 364; i_Max = 378;}
			case 2: {i_Min = 349; i_Max = 358;}
			case 3: {i_Min = 325; i_Max = 336;}
			case 4: {i_Min = 297; i_Max = 309;}
			case 5: {i_Min = 323; i_Max = 344;}
			case 6:
			{
				i_Min = 358;
				i_Max = 376;
			}
			case 7: {i_Min = 291; i_Max = 297;}
			case 8:
			{
				i_Min = 464;
				i_Max = 494;
			}
		}
	}
	else if (StrEqual(vocalize, "playertotherescue"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 379; i_Max = 384;}
			case 2: {i_Min = 359; i_Max = 362;}
			case 3: {i_Min = 337; i_Max = 343;}
			case 4: {i_Min = 310; i_Max = 315;}
			case 5: {i_Min = 345; i_Max = 347;}
			case 6:
			{
				i_Min = 377;
				i_Max = 384;
			}
			case 7: {i_Min = 298; i_Max = 300;}
			case 8:
			{
				i_Min = 495;
				i_Max = 502;
			}
		}
	}
	else if (StrEqual(vocalize, "playerwarncareful"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 385; i_Max = 388;}
			case 2: {i_Min = 363; i_Max = 365;}
			case 3: {i_Min = 344; i_Max = 348;}
			case 4: {i_Min = 316; i_Max = 318;}
			case 5: {i_Min = 348; i_Max = 356;}
			case 6:
			{
				i_Min = 385;
				i_Max = 393;
			}
			case 7: {i_Min = 301; i_Max = 311;}
			case 8:
			{
				i_Min = 503;
				i_Max = 509;
			}
		}
	}
	else if (StrEqual(vocalize, "playerwaithere"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 389; i_Max = 394;}
			case 2: {i_Min = 366; i_Max = 370;}
			case 3: {i_Min = 349; i_Max = 352;}
			case 4: {i_Min = 319; i_Max = 322;}
			case 5: {i_Min = 357; i_Max = 360;}
			case 6:
			{
				i_Min = 394;
				i_Max = 401;
			}
			case 7: {i_Min = 312; i_Max = 316;}
			case 8:
			{
				i_Min = 510;
				i_Max = 515;
			}
		}
	}
	else if (StrEqual(vocalize, "playergrabbedbysmoker"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 395; i_Max = 418;}
			case 2: {i_Min = 371; i_Max = 387;}
			case 3: {i_Min = 353; i_Max = 378;}
			case 4: {i_Min = 323; i_Max = 337;}
			case 5: {i_Min = 361; i_Max = 365;}
			case 6:
			{
				i_Min = 402;
				i_Max = 404;
			}
			case 7: {i_Min = 317; i_Max = 323;}
			case 8:
			{
				i_Min = 516;
				i_Max = 526;
			}
		}
	}
	else
	{
		return Plugin_Continue;
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	if(StrEqual(vocalize, "playeraskready") || StrEqual(vocalize, "playermoveon") || StrEqual(vocalize, "playerhurryup"))
	{
		for (new others=1; others<=MaxClients; others++)
		{
			if(IsClientInGame(others) && GetClientTeam(others) == 2 && IsFakeClient(others) && IsPlayerAlive(others) && client != others)
			{
				CreateTimer(2.0, MakeOthersRespond, others);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:MakeOthersRespond(Handle:timer, any:others)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(others, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 14; i_Max = 17;}
		case 2: {i_Min = 14; i_Max = 17;}
		case 3: {i_Min = 20; i_Max = 22;}
		case 4: {i_Min = 15; i_Max = 18;}
		case 5: {i_Min = 35; i_Max = 41;}
		case 6: {i_Min = 37; i_Max = 38;}
		case 7: {i_Min = 30; i_Max = 31;}
		case 8: {i_Min = 41; i_Max = 57;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(others, s_Scene);
		L4D_MakeClientVocalizeEx(others, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

VocalizeScene(client, String:scenefile[90])
{
	new tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	if(client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if(IsGrabbedBySI[client])
	{
		return Plugin_Continue;
	}
	
	new bool:IsHoldingGrenade[MAXPLAYERS+1] = false;
	new bool:IsThrowingGrenade[MAXPLAYERS+1] = false;
	
	if(IsThrowingGrenade[client])
	{
		IsThrowingGrenade[client] = false;
		
		PerformGrenadeScene(client);
	}
	
	new grenade = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEdict(grenade))
	{
		decl String:currentgrenade[256];
		GetEdictClassname(grenade, currentgrenade, sizeof(currentgrenade));
		if(StrContains(currentgrenade, "pipe_bomb", false) > -1 || StrContains(currentgrenade, "molotov", false) > -1 || StrContains(currentgrenade, "vomitjar", false) > -1)
		{
			IsHoldingGrenade[client] = true;
		}
	}
	
	if(IsHoldingGrenade[client] && (buttons & IN_ATTACK))
	{
		IsThrowingGrenade[client] = true;
		IsHoldingGrenade[client] = false;
	}
	
	return Plugin_Continue;
}

PerformGrenadeScene(thrower)
{
	new i_Type,	i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	GetEntPropString(thrower, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 5: {i_Min = 306; i_Max = 311;}
		case 6:
		{
			i_Min = 343;
			i_Max = 348;
		}
		case 7: {i_Min = 270; i_Max = 276;}
		case 8:
		{
			i_Min = 450;
			i_Max = 455;
		}
	}
	
	new eGrenade = GetEntPropEnt(thrower, Prop_Send, "m_hActiveWeapon");
	if(IsValidEdict(eGrenade))
	{
		decl String:equippedGrenade[256];
		GetEdictClassname(eGrenade, equippedGrenade, sizeof(equippedGrenade));
		if(StrContains(equippedGrenade, "pipe_bomb", false) > -1)
		{
			switch (i_Type)
			{
				case 1: {i_Min = 326; i_Max = 334;}
				case 2: {i_Min = 321; i_Max = 327;}
				case 3: {i_Min = 291; i_Max = 298;}
				case 4: {i_Min = 274; i_Max = 277;}
			}
		}
		else if(StrContains(equippedGrenade, "molotov", false) > -1)
		{
			switch (i_Type)
			{
				case 1: {i_Min = 323; i_Max = 332;}
				case 2: {i_Min = 315; i_Max = 321;}
				case 3: {i_Min = 288; i_Max = 293;}
				case 4: {i_Min = 271; i_Max = 274;}
			}
		}
		else if(StrContains(equippedGrenade, "vomitjar", false) > -1)
		{
			switch (i_Type)
			{
				case 1: {i_Min = 335; i_Max = 337;}
				case 2: {i_Min = 328; i_Max = 330;}
				case 3: {i_Min = 299; i_Max = 304;}
				case 4: {i_Min = 278; i_Max = 280;}
			}
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(thrower, s_Scene);
		L4D_MakeClientVocalizeEx(thrower, CustomVoc[75]);
	}
}

public Action:OnWeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	new melee = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(melee))
	{
		decl String:currentmelee[256];
		GetEntityClassname(melee, currentmelee, sizeof(currentmelee));
		if(StrContains(currentmelee, "chainsaw", false) > -1)
		{
			return Plugin_Handled;
		}
	}
	
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 110; i_Max = 116;}
		case 2: {i_Min = 95; i_Max = 101;}
		case 3: {i_Min = 89; i_Max = 94;}
		case 4: {i_Min = 86; i_Max = 89;}
		case 5: {i_Min = 105; i_Max = 107;}
		case 6: {i_Min = 138; i_Max = 140;}
		case 7: {i_Min = 105; i_Max = 107;}
		case 8: {i_Min = 187; i_Max = 190;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnHealBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(client) || !IsValidSurvivor(victim))
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerOnGround(client) || !IsPlayerOnGround(victim))
	{
		return Plugin_Handled;
	}
	
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	if (client == victim)
	{
		switch (i_Type)
		{
			case 1: {i_Min = 167; i_Max = 178;}
			case 2: {i_Min = 150; i_Max = 163;}
			case 3: {i_Min = 148; i_Max = 157;}
			case 4: {i_Min = 127; i_Max = 133;}
			case 5: {i_Min = 172; i_Max = 179;}
			case 6: {i_Min = 205; i_Max = 218;}
			case 7: {i_Min = 153; i_Max = 162;}
			case 8: {i_Min = 265; i_Max = 276;}
		}
	}
	else
	{
		switch (i_Type)
		{
			case 1: {i_Min = 183; i_Max = 189;}
			case 2: {i_Min = 171; i_Max = 180;}
			case 3: {i_Min = 164; i_Max = 175;}
			case 4: {i_Min = 139; i_Max = 142;}
			case 5: {i_Min = 184; i_Max = 191;}
			case 6: {i_Min = 222; i_Max = 228;}
			case 7: {i_Min = 166; i_Max = 170;}
			case 8: {i_Min = 280; i_Max = 289;}
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}	
	
	return Plugin_Continue;
}

public Action:OnHealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(client) || !IsValidSurvivor(victim))
	{
		return Plugin_Handled;
	}
	
	if(client == victim)
	{
		GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
		
		if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
		{
			Format(s_Model, 9, "coach");
			i_Type = 1;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
		{
			Format(s_Model, 9, "gambler");
			i_Type = 2;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
		{
			Format(s_Model, 9, "mechanic");
			i_Type = 3;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
		{
			Format(s_Model, 9, "producer");
			i_Type = 4;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
		{
			Format(s_Model, 9, "NamVet");
			i_Type = 5;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
		{
			Format(s_Model, 9, "Biker");
			i_Type = 6;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
		{
			Format(s_Model, 9, "Manager");
			i_Type = 7;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
		{
			Format(s_Model, 9, "TeenGirl");
			i_Type = 8;
		}
		
		switch (i_Type)
		{
			case 1: {i_Min = 179; i_Max = 182;}
			case 2: {i_Min = 164; i_Max = 170;}
			case 3: {i_Min = 158; i_Max = 163;}
			case 4: {i_Min = 134; i_Max = 138;}
			case 5: {i_Min = 180; i_Max = 183;}
			case 6: {i_Min = 219; i_Max = 221;}
			case 7: {i_Min = 163; i_Max = 165;}
			case 8: {i_Min = 277; i_Max = 279;}
		}
		i_Rand = GetRandomInt(i_Min, i_Max);
		decl String:s_Temp[40];
		
		switch (i_Type)
		{
			case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
			case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
			case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
			case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
			case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
			case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
			case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
			case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
		}
		{
			decl String:CustomVoc[75];
			decl String:s_Scene[90];
			Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
			CustomVoc[75] = VocalizeScene(client, s_Scene);
			L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
		}
	}
	else
	{
		GetEntPropString(victim, Prop_Data, "m_ModelName", s_Model, 64);
		
		if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
		{
			Format(s_Model, 9, "coach");
			i_Type = 1;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
		{
			Format(s_Model, 9, "gambler");
			i_Type = 2;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
		{
			Format(s_Model, 9, "mechanic");
			i_Type = 3;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
		{
			Format(s_Model, 9, "producer");
			i_Type = 4;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
		{
			Format(s_Model, 9, "NamVet");
			i_Type = 5;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
		{
			Format(s_Model, 9, "Biker");
			i_Type = 6;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
		{
			Format(s_Model, 9, "Manager");
			i_Type = 7;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
		{
			Format(s_Model, 9, "TeenGirl");
			i_Type = 8;
		}
		
		switch (i_Type)
		{
			case 1: {i_Min = 179; i_Max = 182;}
			case 2: {i_Min = 164; i_Max = 170;}
			case 3: {i_Min = 158; i_Max = 163;}
			case 4: {i_Min = 134; i_Max = 138;}
			case 5: {i_Min = 180; i_Max = 183;}
			case 6: {i_Min = 219; i_Max = 221;}
			case 7: {i_Min = 163; i_Max = 165;}
			case 8: {i_Min = 277; i_Max = 279;}
		}
		i_Rand = GetRandomInt(i_Min, i_Max);
		decl String:s_Temp[40];
		
		switch (i_Type)
		{
			case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
			case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
			case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
			case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
			case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
			case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
			case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
			case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
		}
		{
			decl String:CustomVoc[75];
			decl String:s_Scene[90];
			Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
			CustomVoc[75] = VocalizeScene(victim, s_Scene);
			L4D_MakeClientVocalizeEx(victim, CustomVoc[75]);
		}
		
		CreateTimer(2.0, ThanksDelay, victim);
		CreateTimer(4.0, YouAreWelcomeDelay, client);
	}
	
	return Plugin_Continue;
}

public Action:ThanksDelay(Handle:timer, any:victim)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(victim, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 87; i_Max = 92;}
		case 2: {i_Min = 80; i_Max = 82;}
		case 3: {i_Min = 72; i_Max = 74;}
		case 4: {i_Min = 70; i_Max = 76;}
		case 5: {i_Min = 74; i_Max = 84;}
		case 6: {i_Min = 96; i_Max = 105;}
		case 7: {i_Min = 70; i_Max = 78;}
		case 8: {i_Min = 125; i_Max = 143;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(victim, s_Scene);
		L4D_MakeClientVocalizeEx(victim, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:YouAreWelcomeDelay(Handle:timer, any:client)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 222; i_Max = 226;}
		case 2: {i_Min = 217; i_Max = 233;}
		case 3: {i_Min = 204; i_Max = 213;}
		case 4: {i_Min = 176; i_Max = 185;}
		case 5: {i_Min = 231; i_Max = 240;}
		case 6:
		{
			i_Min = 271;
			i_Max = 282;
		}
		case 7: {i_Min = 197; i_Max = 208;}
		case 8:
		{
			i_Min = 360;
			i_Max = 382;
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:OnSupplyUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 216; i_Max = 221;}
		case 2: {i_Min = 212; i_Max = 216;}
		case 3: {i_Min = 196; i_Max = 203;}
		case 4: {i_Min = 171; i_Max = 175;}
		case 5: {i_Min = 227; i_Max = 230;}
		case 6:
		{
			i_Min = 266;
			i_Max = 270;
		}
		case 7: {i_Min = 192; i_Max = 196;}
		case 8:
		{
			i_Min = 355;
			i_Max = 359;
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reviver = GetClientOfUserId(GetEventInt(event, "userid"));
	new revivee = GetClientOfUserId(GetEventInt(event, "subject"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(reviver))
	{
		return Plugin_Handled;
	}
	
	GetEntPropString(reviver, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	IsReviving[revivee] = true;
	HasRevived[revivee] = false;
	
	if(GetEntProp(revivee, Prop_Send, "m_currentReviveCount") == 2)
	{
		switch (i_Type)
		{
			case 1: {i_Min = 316; i_Max = 322;}
			case 2: {i_Min = 312; i_Max = 314;}
			case 3: {i_Min = 285; i_Max = 287;}
			case 4: {i_Min = 266; i_Max = 270;}
			case 5: {i_Min = 299; i_Max = 305;}
			case 6:
			{
				i_Min = 336;
				i_Max = 342;
			}
			case 7: {i_Min = 265; i_Max = 269;}
			case 8:
			{
				i_Min = 443;
				i_Max = 449;
			}
		}
	}
	else
	{
		switch (i_Type)
		{
			case 1: {i_Min = 264; i_Max = 315;}
			case 2: {i_Min = 254; i_Max = 311;}
			case 3: {i_Min = 239; i_Max = 284;}
			case 4: {i_Min = 209; i_Max = 265;}
			case 5: {i_Min = 254; i_Max = 298;}
			case 6:
			{
				i_Min = 297;
				i_Max = 335;
			}
			case 7: {i_Min = 220; i_Max = 264;}
			case 8:
			{
				i_Min = 394;
				i_Max = 442;
			}
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(reviver, s_Scene);
		L4D_MakeClientVocalizeEx(reviver, CustomVoc[75]);
	}
	
	CreateTimer(1.5, RevivingDelay, revivee);
	
	return Plugin_Continue;
}

public Action:RevivingDelay(Handle:timer, any:revivee)
{
	if(!IsValidSurvivor(revivee))
	{
		return Plugin_Handled;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(revivee, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 227; i_Max = 263;}
		case 2: {i_Min = 234; i_Max = 253;}
		case 3: {i_Min = 214; i_Max = 238;}
		case 4: {i_Min = 186; i_Max = 208;}
		case 5: {i_Min = 241; i_Max = 253;}
		case 6:
		{
			i_Min = 283;
			i_Max = 296;
		}
		case 7: {i_Min = 209; i_Max = 219;}
		case 8:
		{
			i_Min = 383;
			i_Max = 393;
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(revivee, s_Scene);
		L4D_MakeClientVocalizeEx(revivee, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:OnReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reviver = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	if(!IsValidSurvivor(reviver) || !IsValidSurvivor(victim) || HasRevived[victim] || !IsAlreadyIncapacitated[victim])
	{
		return;
	}
	
	IsAlreadyIncapacitated[victim] = true;
	IsReviving[victim] = false;
	HasRevived[victim] = false;
}

public Action:OnReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(victim) || !IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	GetEntPropString(victim, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	IsReviving[victim] = false;
	HasRevived[victim] = true;
	IsAlreadyIncapacitated[victim] = false;
	
	switch (i_Type)
	{
		case 1: {i_Min = 87; i_Max = 92;}
		case 2: {i_Min = 80; i_Max = 82;}
		case 3: {i_Min = 72; i_Max = 74;}
		case 4: {i_Min = 70; i_Max = 76;}
		case 5: {i_Min = 74; i_Max = 84;}
		case 6: {i_Min = 96; i_Max = 105;}
		case 7: {i_Min = 70; i_Max = 78;}
		case 8: {i_Min = 125; i_Max = 143;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(victim, s_Scene);
		L4D_MakeClientVocalizeEx(victim, CustomVoc[75]);
	}
	
	CreateTimer(2.5, YouAreWelcomeDelay, client);
	
	return Plugin_Continue;
}

public Action:OnPlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(!IsValidSurvivor(client) || GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		return Plugin_Handled;
	}
	
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	if(IsAlreadyIncapacitated[client] || HasRevived[client] || IsReviving[client] || GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		return Plugin_Handled;
	}
	
	IsAlreadyIncapacitated[client] = true;
	IsReviving[client] = false;
	HasRevived[client] = false;
	
	switch (i_Type)
	{
		case 1: {i_Min = 135; i_Max = 138;}
		case 2: {i_Min = 120; i_Max = 123;}
		case 3: {i_Min = 110; i_Max = 112;}
		case 4: {i_Min = 100; i_Max = 103;}
		case 5: {i_Min = 128; i_Max = 131;}
		case 6: {i_Min = 160; i_Max = 162;}
		case 7: {i_Min = 126; i_Max = 130;}
		case 8: {i_Min = 222; i_Max = 225;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	CreateTimer(7.0, CallForHelpDelay, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:CallForHelpDelay(Handle:timer, any:client)
{
	if(!IsValidEntity(client) || !IsAlreadyIncapacitated[client] || HasRevived[client] || IsReviving[client])
	{
		return Plugin_Stop;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 151; i_Max = 166;}
		case 2: {i_Min = 135; i_Max = 149;}
		case 3: {i_Min = 125; i_Max = 147;}
		case 4: {i_Min = 112; i_Max = 126;}
		case 5: {i_Min = 147; i_Max = 171;}
		case 6: {i_Min = 180; i_Max = 204;}
		case 7: {i_Min = 139; i_Max = 152;}
		case 8: {i_Min = 238; i_Max = 264;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	IsAlreadyIncapacitated[client] = true;
	IsReviving[client] = false;
	HasRevived[client] = false;
	AlreadyCalledForHelp[client] = true;
	
	if(AlreadyCalledForHelp[client] && (!IsReviving[client] || !HasRevived[client]))
	{
		new i_Type, i_Rand, i_Min, i_Max;
		decl String:s_Model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
		
		if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
		{
			Format(s_Model, 9, "coach");
			i_Type = 1;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
		{
			Format(s_Model, 9, "gambler");
			i_Type = 2;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
		{
			Format(s_Model, 9, "mechanic");
			i_Type = 3;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
		{
			Format(s_Model, 9, "producer");
			i_Type = 4;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
		{
			Format(s_Model, 9, "NamVet");
			i_Type = 5;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
		{
			Format(s_Model, 9, "Biker");
			i_Type = 6;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
		{
			Format(s_Model, 9, "Manager");
			i_Type = 7;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
		{
			Format(s_Model, 9, "TeenGirl");
			i_Type = 8;
		}
		
		switch (i_Type)
		{
			case 1: {i_Min = 151; i_Max = 166;}
			case 2: {i_Min = 135; i_Max = 149;}
			case 3: {i_Min = 125; i_Max = 147;}
			case 4: {i_Min = 112; i_Max = 126;}
			case 5: {i_Min = 147; i_Max = 171;}
			case 6: {i_Min = 180; i_Max = 204;}
			case 7: {i_Min = 139; i_Max = 152;}
			case 8: {i_Min = 238; i_Max = 264;}
		}
		i_Rand = GetRandomInt(i_Min, i_Max);
		decl String:s_Temp[40];
		
		switch (i_Type)
		{
			case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
			case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
			case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
			case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
			case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
			case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
			case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
			case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
		}
		{
			decl String:CustomVoc[75];
			decl String:s_Scene[90];
			Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
			CustomVoc[75] = VocalizeScene(client, s_Scene);
			L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
		}
		
		AlreadyCalledForHelp[client] = false;
		CreateTimer(7.0, ResetCallForHelp, client);
	}
	
	return Plugin_Continue;
}

public Action:ResetCallForHelp(Handle:timer, any:client)
{
	AlreadyCalledForHelp[client] = true;
	return Plugin_Stop;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(victim, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(!IsValidSurvivor(victim) || attacker <= 0)
	{
		return Plugin_Handled;
	}
	
	if(IsGrabbedBySI[victim])
	{
		return Plugin_Handled;
	}
	
	AlreadyHurt[victim] = true;
	
	if(AlreadyHurt[victim])
	{
		if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
		{
			Format(s_Model, 9, "coach");
			i_Type = 1;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
		{
			Format(s_Model, 9, "gambler");
			i_Type = 2;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
		{
			Format(s_Model, 9, "mechanic");
			i_Type = 3;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
		{
			Format(s_Model, 9, "producer");
			i_Type = 4;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
		{
			Format(s_Model, 9, "NamVet");
			i_Type = 5;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
		{
			Format(s_Model, 9, "Biker");
			i_Type = 6;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
		{
			Format(s_Model, 9, "Manager");
			i_Type = 7;
		}
		else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
		{
			Format(s_Model, 9, "TeenGirl");
			i_Type = 8;
		}
		
		if(IsSurvivorDown(victim))
		{
			switch (i_Type)
			{
				case 1: {i_Min = 147; i_Max = 150;}
				case 2: {i_Min = 131; i_Max = 134;}
				case 3: {i_Min = 119; i_Max = 124;}
				case 4: {i_Min = 108; i_Max = 111;}
				case 5: {i_Min = 142; i_Max = 146;}
				case 6: {i_Min = 174; i_Max = 179;}
				case 7: {i_Min = 136; i_Max = 138;}
				case 8: {i_Min = 234; i_Max = 237;}
			}
		}
		else
		{
			if(GetEntProp(victim, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
			{
				switch (i_Type)
				{
					case 1: {i_Min = 139; i_Max = 146;}
					case 2: {i_Min = 124; i_Max = 130;}
					case 3: {i_Min = 113; i_Max = 118;}
					case 4: {i_Min = 104; i_Max = 107;}
					case 5: {i_Min = 132; i_Max = 141;}
					case 6: {i_Min = 163; i_Max = 173;}
					case 7: {i_Min = 131; i_Max = 135;}
					case 8: {i_Min = 226; i_Max = 233;}
				}
			}
			else
			{
				switch (i_Type)
				{
					case 1: {i_Min = 117; i_Max = 134;}
					case 2: {i_Min = 102; i_Max = 119;}
					case 3: {i_Min = 95; i_Max = 109;}
					case 4: {i_Min = 90; i_Max = 99;}
					case 5: {i_Min = 108; i_Max = 127;}
					case 6: {i_Min = 141; i_Max = 159;}
					case 7: {i_Min = 108; i_Max = 125;}
					case 8: {i_Min = 191; i_Max = 221;}
				}
			}
		}
		i_Rand = GetRandomInt(i_Min, i_Max);
		decl String:s_Temp[40];
		
		switch (i_Type)
		{
			case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
			case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
			case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
			case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
			case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
			case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
			case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
			case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
		}
		{
			decl String:CustomVoc[75];
			decl String:s_Scene[90];
			Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
			CustomVoc[75] = VocalizeScene(victim, s_Scene);
			L4D_MakeClientVocalizeEx(victim, CustomVoc[75]);
		}
		
		AlreadyHurt[victim] = false;
		CreateTimer(2.5, ResetHurt, victim);
	}
	
	return Plugin_Continue;
}

public Action:ResetHurt(Handle:timer, any:victim)
{
	AlreadyHurt[victim] = true;
	return Plugin_Stop;
}

public Action:OnDefibrillatorBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new saver = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidSurvivor(saver) || !IsPlayerOnGround(saver))
	{
		return Plugin_Handled;
	}
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(saver, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 338; i_Max = 341;}
		case 2: {i_Min = 331; i_Max = 335;}
		case 3: {i_Min = 305; i_Max = 310;}
		case 4: {i_Min = 281; i_Max = 286;}
		case 5: {i_Min = 312; i_Max = 313;}
		case 6:
		{
			i_Min = 349;
			i_Max = 350;
		}
		case 7: {i_Min = 277; i_Max = 277;}
		case 8:
		{
			i_Min = 456;
			i_Max = 457;
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(saver, s_Scene);
		L4D_MakeClientVocalizeEx(saver, CustomVoc[75]);
	}
	
	return Plugin_Continue;
}

public Action:OnDefibrillatorUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new saver = GetClientOfUserId(GetEventInt(event, "userid"));
	new savee = GetClientOfUserId(GetEventInt(event, "subject"));
	if(!IsValidSurvivor(savee) || !IsValidSurvivor(saver))
	{
		return Plugin_Handled;
	}
	
	IsAlreadyIncapacitated[savee] = false;
	IsReviving[savee] = false;
	HasRevived[savee] = false;
	AlreadyCalledForHelp[savee] = false;
	AlreadyHurt[savee] = false;
	
	IsGrabbedBySI[savee] = false;
	
	CreateTimer(2.0, DefibbedDelay, savee);
	CreateTimer(4.0, YouAreWelcomeDelay, saver);
	
	return Plugin_Continue;
}

public Action:DefibbedDelay(Handle:timer, any:savee)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(savee, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 342; i_Max = 352;}
		case 2: {i_Min = 336; i_Max = 343;}
		case 3: {i_Min = 311; i_Max = 317;}
		case 4: {i_Min = 287; i_Max = 292;}
		case 5: {i_Min = 74; i_Max = 84;}
		case 6: {i_Min = 96; i_Max = 105;}
		case 7: {i_Min = 70; i_Max = 78;}
		case 8: {i_Min = 125; i_Max = 143;}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(savee, s_Scene);
		L4D_MakeClientVocalizeEx(savee, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:OnTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new grabbed = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(grabbed))
	{
		return Plugin_Handled;
	}
	
	IsGrabbedBySI[grabbed] = true;
	
	CreateTimer(0.1, GrabbedBySmokerDelay, grabbed);
	
	return Plugin_Continue;
}

public Action:GrabbedBySmokerDelay(Handle:timer, any:grabbed)
{
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	GetEntPropString(grabbed, Prop_Data, "m_ModelName", s_Model, 64);
	
	if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
	{
		Format(s_Model, 9, "coach");
		i_Type = 1;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
	{
		Format(s_Model, 9, "gambler");
		i_Type = 2;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		Format(s_Model, 9, "mechanic");
		i_Type = 3;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
	{
		Format(s_Model, 9, "producer");
		i_Type = 4;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
	{
		Format(s_Model, 9, "NamVet");
		i_Type = 5;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
	{
		Format(s_Model, 9, "Biker");
		i_Type = 6;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
	{
		Format(s_Model, 9, "Manager");
		i_Type = 7;
	}
	else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		Format(s_Model, 9, "TeenGirl");
		i_Type = 8;
	}
	
	switch (i_Type)
	{
		case 1: {i_Min = 395; i_Max = 418;}
		case 2: {i_Min = 371; i_Max = 387;}
		case 3: {i_Min = 353; i_Max = 378;}
		case 4: {i_Min = 323; i_Max = 337;}
		case 5: {i_Min = 361; i_Max = 365;}
		case 6:
		{
			i_Min = 402;
			i_Max = 404;
		}
		case 7: {i_Min = 317; i_Max = 323;}
		case 8:
		{
			i_Min = 516;
			i_Max = 526;
		}
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
	}
	{
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(grabbed, s_Scene);
		L4D_MakeClientVocalizeEx(grabbed, CustomVoc[75]);
	}
	
	return Plugin_Stop;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new busted = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidInfected(busted) || GetEntProp(busted, Prop_Send, "m_zombieClass") != 8)
	{
		return Plugin_Handled;
	}
	
	for(new busters=1; busters<=MaxClients; busters++)
	{
		if(IsClientInGame(busters) && GetClientTeam(busters) == 2 && IsPlayerAlive(busters) && !IsSurvivorDown(busters))
		{
			new i_Type, i_Rand, i_Min, i_Max;
			decl String:s_Model[64];
			GetEntPropString(busters, Prop_Data, "m_ModelName", s_Model, 64);
			
			if(strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0)
			{
				Format(s_Model, 9, "coach");
				i_Type = 1;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0)
			{
				Format(s_Model, 9, "gambler");
				i_Type = 2;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0)
			{
				Format(s_Model, 9, "mechanic");
				i_Type = 3;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0)
			{
				Format(s_Model, 9, "producer");
				i_Type = 4;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0)
			{
				Format(s_Model, 9, "NamVet");
				i_Type = 5;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0)
			{
				Format(s_Model, 9, "Biker");
				i_Type = 6;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0)
			{
				Format(s_Model, 9, "Manager");
				i_Type = 7;
			}
			else if(strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0)
			{
				Format(s_Model, 9, "TeenGirl");
				i_Type = 8;
			}
			
			switch (i_Type)
			{
				case 1: {i_Min = 7; i_Max = 13;}
				case 2: {i_Min = 8; i_Max = 13;}
				case 3: {i_Min = 10; i_Max = 19;}
				case 4: {i_Min = 9; i_Max = 14;}
				case 5: {i_Min = 11; i_Max = 34;}
				case 6: {i_Min = 18; i_Max = 36;}
				case 7: {i_Min = 6; i_Max = 29;}
				case 8: {i_Min = 18; i_Max = 40;}
			}
			i_Rand = GetRandomInt(i_Min, i_Max);
			decl String:s_Temp[40];
			
			switch (i_Type)
			{
				case 1: Format(s_Temp, sizeof(s_Temp), "%s", g_Coach[i_Rand]);
				case 2: Format(s_Temp, sizeof(s_Temp), "%s", g_Nick[i_Rand]);
				case 3: Format(s_Temp, sizeof(s_Temp), "%s", g_Ellis[i_Rand]);
				case 4: Format(s_Temp, sizeof(s_Temp), "%s", g_Rochelle[i_Rand]);
				case 5: Format(s_Temp, sizeof(s_Temp), "%s", g_Bill[i_Rand]);
				case 6: Format(s_Temp, sizeof(s_Temp), "%s", g_Francis[i_Rand]);
				case 7: Format(s_Temp, sizeof(s_Temp), "%s", g_Louis[i_Rand]);
				case 8: Format(s_Temp, sizeof(s_Temp), "%s", g_Zoey[i_Rand]);
			}
			{
				decl String:CustomVoc[75];
				decl String:s_Scene[90];
				Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
				CustomVoc[75] = VocalizeScene(busters, s_Scene);
				L4D_MakeClientVocalizeEx(busters, CustomVoc[75]);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnGrabbedByInfected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new troubler = GetClientOfUserId(GetEventInt(event, "userid"));
	new troubled = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(troubled) || !IsValidInfected(troubler))
	{
		return;
	}
	
	IsGrabbedBySI[troubled] = true;
}

public Action:OnInfectedDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new deadly = GetClientOfUserId(GetEventInt(event, "userid"));
	new friendly = GetClientOfUserId(GetEventInt(event, "victim"));
	if(!IsValidSurvivor(friendly) || !IsValidInfected(deadly))
	{
		return;
	}
	
	IsGrabbedBySI[friendly] = false;
}

public IsValidSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

public IsValidInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

public IsSurvivorDown(client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	else
	{
		return false;
	}
}

public IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return true;
	}
	else
	{
		return false;
	}
}

