#include <sourcemod> 
#include <sdktools> 
#include "vocalizefatigue" 
public Plugin:myinfo =  
{ 
	name = "Modeled Vocalization", 
	author = "DeathChaos", 
	description = "Survivors will vocalize based on Model rather than actual character", 
	version = "1.0",
} 
// Vocalize for Left 4 Dead 2
static const String:g_Coach[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07",
	"Laughter01", "Laughter04", "Laughter06", "Laughter07", "Laughter13", "Laughter14", "Laughter22",
	"Yes03", "Yes05", "Yes07", "Yes10",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No10", "No11", "No12", "WorldC2M132", "WorldC5M3B13", "WorldC5M5B04" ,"WorldSigns24", "WorldSigns26",
	"WorldC3M207", "AskReady01", "AskReady02", "AskReady03", "AskReady04", "AskReady05", "AskReady06", "AskReady07", "AskReady08",
	"ReactionNegative01", "ReactionNegative02", "ReactionNegative03", "ReactionNegative07", "ReactionNegative08", "ReactionNegative09", "ReactionNegative10", "ReactionNegative14", "ReactionNegative15", "ReactionNegative17", "ReactionNegative18", "ReactionNegative19", "WorldC5M4B03", "WorldC5M3B28",
	"BattleCry04", "BattleCry06", "BattleCry09", "Hurrah01", "Hurrah02", "Hurrah03", "Hurrah04", "Hurrah05", "Hurrah06", "Hurrah07", "Hurrah08", "Hurrah09", "Hurrah10", "Hurrah11", "Hurrah12", "Hurrah13", "Hurrah14", "Hurrah15", "Hurrah16", "Hurrah17", "Hurrah18", "Hurrah19", "Hurrah20", "Hurrah21", "Hurrah23", "Hurrah24", "Hurrah26", "PositiveNoise03", "PositiveNoise10",
	"Thanks01", "Thanks02", "Thanks04", "Thanks05", "Thanks06", "Thanks07",
	"DLC1_C6M2_SuitcasePistols01", "Taunt01", "Taunt02", "Taunt03", "Taunt04", "Taunt05", "Taunt06", "Taunt07", "Taunt08", "WorldC2M2B05" ,"WorldC2M2B06", "WorldC3M116", "WorldC3M117",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07"
};
static const String:g_Nick[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08",
	"Laughter01", "Laughter03", "Laughter06", "Laughter15", "Laughter16", "Laughter17",
	"Yes01", "Yes04", "Yes05", "Yes08",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No10", "No11", "No12", "EllisInterrupt03",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOtherC101", "HealOtherC102", "HealOtherC103", "HealOtherC104", "HealOtherC105"
};
static const String:g_Ellis[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09", "Sorry10",
	"Laughter04", "Laughter05", "Laughter06", "Laughter09", "Laughter13b", "Laughter13c", "Laughter13d", "Laughter13e", "WorldC2M2B23", "Laughter14",
	"Yes01", "Yes03", "Yes06",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No10", "No11", "No12",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07", "HealOther08", "HealOther09", "HealOtherC103", "HealOtherC104", "HealOtherC105"
};
static const String:g_Rochelle[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "WitchChasing08",
	"Laughter01", "Laughter04", "Laughter12", "Laughter13", "Laughter14", "Laughter17",
	"Yes01", "Yes05", "Yes07", "Yes08",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No10", "No11", "No12", "DLC1_C6M3_FinaleChat17", "DLC1_C6M3_FinaleChat18", "DLC1_C6M3_FinaleChat20",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04"
};
// Vocalize for Left 4 Dead
static const String:g_Bill[][] =
{
	"Sorry01", "Sorry02" , "Sorry03", "Sorry04", "Sorry05", "Sorry07", "Sorry08", "Sorry09", "Sorry10", "Sorry11", "Sorry12",
	"Laughter01", "Laughter02", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter10", "Laughter11", "Laughter12", "Laughter13", "Laughter14", "ReactionPositive02", "ReactionPositive05", "ReactionPositive06", "ReactionPositive07", "ReactionPositive08", "ViolenceAwe06", "Taunt01", "Taunt02", "Taunt07", "Taunt08", "Taunt019",
	"GenericResponses06", "Yes02", "Yes03", "Yes04", "Yes05", "Yes06", "YouAreWelcome10",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No10", "No11", "No14", "No15", "C6DLC3SECONDSAFEROOM02",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07", "HealOther08"
};
static const String:g_Francis[][] =
{
	"Sorry01", "Sorry02", "Sorry03", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09", "Sorry10", "Sorry12", "Sorry13", "Sorry14", "Sorry15", "Sorry16", "Sorry17", "Sorry18", "GenericResponses11",
	"Laughter01", "Laughter02", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09", "Laughter11", "Laughter12", "Laughter13", "Laughter14","DLC2GasTanks04", "HurtMajor04", "ReactionPositive01", "ViolenceAwe07", "Taunt05", "Taunt06", "Taunt07",
	"Yes01", "Yes03",
	"No01", "No02", "No03", "No04", "No05", "No06", "No07","No08", "No09", "No11", "No14", "No15", "No16", "No17", "No18", "DLC1_C6M1_InitialMeeting02", "DLC1_C6M1_InitialMeeting03", "DLC1_C6M1_InitialMeeting04", "DLC1_C6M1_InitialMeeting40",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOther06", "HealOther07"
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05"
};
static const String:g_Zoey[][] =
{
	"Sorry11", "Sorry12", "Sorry04", "Sorry05", "Sorry06", "Sorry07", "Sorry08", "Sorry09","Sorry10", "Sorry13", "Sorry14", "Sorry15", "Sorry16", "Sorry17", "Sorry18", "Sorry20", "Sorry23", "DLC1_C6M3_FinaleChat02","DLC1_C6M3_FinaleChat02",
	"Laughter11", "Laughter12", "Laughter04", "Laughter05", "Laughter06", "Laughter07", "Laughter08", "Laughter09","Laughter10", "Laughter13", "Laughter01", "Laughter02", "Laughter03", "Laughter14", "Laughter15", "Laughter16", "Laughter17", "Laughter18","Laughter19", "Laughter20", "PositiveNoise02","Laughter21", "DLC2GasTanks03", 
	"Yes01", "Yes02", "Yes03", "Yes04", "Yes05", "Yes06", "Yes07", "Yes08","Yes09", "Yes10", "Yes13", "Yes14", "Yes15", "Yes16", "Yes17", "Yes18", "GenericResponses04",
	"NegativeNoise09","Uncertain12", "DLC1_C6M1_InitialMeeting25","DLC1_C6M1_InitialMeeting27", "DLC1_C6M1_InitialMeeting28","DLC1_C6M1_InitialMeeting29" ,"No01", "No07", "No08", "No09", "No10", "No11", "No14", "No15", "No18", "No21", "No22", "No23", "No24", "No25", "No31", "No36", "No38","No43", "No48", "No49", "NegativeNoise02",
	"AskReady03", "AskReady11", "AskReady12", "AskReady13", "AskReady14", "AskReady15", "AskReady17", "AskReady18", "AskReady19", "AskReady21",
	"NegativeNoise01", "NegativeNoise04", "NegativeNoise05", "NegativeNoise06", "NegativeNoise07", "NegativeNoise08", "NegativeNoise10", "NegativeNoise14", "NegativeNoise15", "ReactionNegative01", "ReactionNegative03", "ReactionNegative04", "ReactionNegative23", "ReactionNegative26",
	"Hurrah07", "Hurrah10", "Hurrah13", "Hurrah18", "Hurrah19", "Hurrah20", "Hurrah23", "Hurrah31", "Hurrah35", "Hurrah38", "Hurrah46", "Hurrah48", "Hurrah53", "Hurrah54", "Hurrah55", "Hurrah58",
	"Thanks01", "Thanks02", "Thanks03", "Thanks04", "Thanks06", "Thanks07", "Thanks08", "Thanks09", "Thanks13", "Thanks19", "Thanks20", "Thanks23", "Thanks24", "Thanks25", "Thanks27", "Thanks28", "Thanks30", "ReactionPositive12" ,"ReactionPositive27",
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
	"HealOther01", "HealOther02", "HealOther03", "HealOther04", "HealOther05", "HealOtherCombat07", "HealOtherCombat08", "HealOtherCombat09", "HealOtherCombat10", "HealOtherCombat11"
};
public OnPluginStart() 
{ 
	HookEvent("weapon_reload", PlayerReload_Event);
	HookEvent("heal_begin", PlayerHeal_Event);
	HookEvent("heal_success",HealSuccess_Event);
} 
public Action:L4D_OnClientVocalize(client, const String:vocalize[]) 
{ 
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize"); 
	} 
	
	if (StrEqual(vocalize,"playersorry"))
	{ 
		
		switch (i_Type)
		{
			case 1: i_Max = 7; // Coach
			case 2: i_Max = 7; // Nick
			case 3: i_Max = 10; // Ellis
			case 4: i_Max = 9; // Rochelle
			case 5: i_Max = 11; // Bill
			case 6: i_Max = 18; // Francis
			case 7: i_Max = 6; // Louis
			case 8: i_Max = 19; // Zoey
		}
		
		
	}
	
	else if(StrEqual(vocalize,"playerlaugh"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 8; i_Max = 14;} // Coach
			case 2: {i_Min = 8; i_Max = 13;} // Nick
			case 3: {i_Min = 11; i_Max = 20;} // Ellis
			case 4: {i_Min = 10; i_Max = 15;} // Rochelle
			case 5: {i_Min = 12; i_Max = 35;} // Bill
			case 6: {i_Min = 19; i_Max = 37;} // Francis
			case 7: {i_Min = 7; i_Max = 30;} // Louis
			case 8: {i_Min = 20; i_Max = 42;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playeryes"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 14; i_Max = 17;} // Coach
			case 2: {i_Min = 15; i_Max = 18;} // Nick
			case 3: {i_Min = 21; i_Max = 23;} // Ellis
			case 4: {i_Min = 16; i_Max = 19;} // Rochelle
			case 5: {i_Min = 36; i_Max = 42;} // Bill
			case 6: {i_Min = 38; i_Max = 39;} // Francis
			case 7: {i_Min = 31; i_Max = 32;} // Louis
			case 8: {i_Min = 43; i_Max = 59;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerno"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 19; i_Max = 35;} // Coach
			case 2: {i_Min = 18; i_Max = 30;} // Nick
			case 3: {i_Min = 24; i_Max = 35;} // Ellis
			case 4: {i_Min = 20; i_Max = 34;} // Rochelle
			case 5: {i_Min = 43; i_Max = 56;} // Bill
			case 6: {i_Min = 40; i_Max = 60;} // Francis
			case 7: {i_Min = 33; i_Max = 40;} // Louis
			case 8: {i_Min = 60; i_Max = 86;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playeraskready"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 36; i_Max = 44;} // Coach
			case 2: {i_Min = 31; i_Max = 43;} // Nick
			case 3: {i_Min = 36; i_Max = 38;} // Ellis
			case 4: {i_Min = 35; i_Max = 37;} // Rochelle
			case 5: {i_Min = 57; i_Max = 62;} // Bill
			case 6: {i_Min = 61; i_Max = 70;} // Francis
			case 7: {i_Min = 41; i_Max = 48;} // Louis
			case 8: {i_Min = 87; i_Max = 96;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playernegative") || StrEqual(vocalize,"playerswear"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 45; i_Max = 58;} // Coach
			case 2: {i_Min = 44; i_Max = 66;} // Nick
			case 3: {i_Min = 39; i_Max = 51;} // Ellis
			case 4: {i_Min = 38; i_Max = 52;} // Rochelle
			case 5: {i_Min = 63; i_Max = 69;} // Bill
			case 6: {i_Min = 71; i_Max = 84;} // Francis
			case 7: {i_Min = 49; i_Max = 55;} // Louis
			case 8: {i_Min = 97; i_Max = 110;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerhurrah"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 59; i_Max = 87;} // Coach
			case 2: {i_Min = 67; i_Max = 79;} // Nick
			case 3: {i_Min = 52; i_Max = 72;} // Ellis
			case 4: {i_Min = 53; i_Max = 70;} // Rochelle
			case 5: {i_Min = 70; i_Max = 74;} // Bill
			case 6: {i_Min = 85; i_Max = 98;} // Francis
			case 7: {i_Min = 56; i_Max = 70;} // Louis
			case 8: {i_Min = 111; i_Max = 126;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerthanks"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 88; i_Max = 93;} // Coach
			case 2: {i_Min = 80; i_Max = 82;} // Nick
			case 3: {i_Min = 73; i_Max = 75;} // Ellis
			case 4: {i_Min = 71; i_Max = 77;} // Rochelle
			case 5: {i_Min = 75; i_Max = 85;} // Bill
			case 6: {i_Min = 99; i_Max = 109;} // Francis
			case 7: {i_Min = 71; i_Max = 79;} // Louis
			case 8: {i_Min = 127; i_Max = 144;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playertaunt") || StrEqual(vocalize,"survivortaunt"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 94; i_Max = 106;} // Coach
			case 2: {i_Min = 83; i_Max = 91;} // Nick
			case 3: {i_Min = 76; i_Max = 87;} // Ellis
			case 4: {i_Min = 78; i_Max = 83;} // Rochelle
			case 5: {i_Min = 86; i_Max = 99;} // Bill
			case 6: {i_Min = 110; i_Max = 135;} // Francis
			case 7: {i_Min = 80; i_Max = 99;} // Louis
			case 8: {i_Min = 145; i_Max = 179;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerlookout") || StrEqual(vocalize,"survivorvocalizelookout") || StrEqual(vocalize,"survivorlookout"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 107; i_Max = 110;} // Coach
			case 2: {i_Min = 92; i_Max = 94;} // Nick
			case 3: {i_Min = 88; i_Max = 90;} // Ellis
			case 4: {i_Min = 84; i_Max = 86;} // Rochelle
			case 5: {i_Min = 100; i_Max = 105;} // Bill
			case 6: {i_Min = 136; i_Max = 141;} // Francis
			case 7: {i_Min = 100; i_Max = 105;} // Louis
			case 8: {i_Min = 180; i_Max = 187;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerreload") || StrEqual(vocalize,"reloading")  || StrEqual(vocalize,"playerreloading"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 111; i_Max = 117;} // Coach
			case 2: {i_Min = 95; i_Max = 101;} // Nick
			case 3: {i_Min = 91; i_Max = 96;} // Ellis
			case 4: {i_Min = 87; i_Max = 90;} // Rochelle
			case 5: {i_Min = 106; i_Max = 108;} // Bill
			case 6: {i_Min = 142; i_Max = 144;} // Francis
			case 7: {i_Min = 106; i_Max = 108;} // Louis
			case 8: {i_Min = 188; i_Max = 191;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerminorhurt") || StrEqual(vocalize,"playerhurtminor"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 118; i_Max = 124;} // Coach
			case 2: {i_Min = 102; i_Max = 108;} // Nick
			case 3: {i_Min = 97; i_Max = 105;} // Ellis
			case 4: {i_Min = 91; i_Max = 96;} // Rochelle
			case 5: {i_Min = 109; i_Max = 119;} // Bill
			case 6: {i_Min = 145; i_Max = 152;} // Francis
			case 7: {i_Min = 109; i_Max = 116;} // Louis
			case 8: {i_Min = 192; i_Max = 204;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playermajorhurt") || StrEqual(vocalize, "playerhurtmajor"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 125; i_Max = 135;} // Coach
			case 2: {i_Min = 109; i_Max = 119;} // Nick
			case 3: {i_Min = 106; i_Max = 111;} // Ellis
			case 4: {i_Min = 97; i_Max = 100;} // Rochelle
			case 5: {i_Min = 120; i_Max = 128;} // Bill
			case 6: {i_Min = 153; i_Max = 163;} // Francis
			case 7: {i_Min = 117; i_Max = 126;} // Louis
			case 8: {i_Min = 205; i_Max = 222;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerincapacitatedinitial") || StrEqual(vocalize,"playerincapacitated"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 136; i_Max = 139;} // Coach
			case 2: {i_Min = 120; i_Max = 123;} // Nick
			case 3: {i_Min = 112; i_Max = 114;} // Ellis
			case 4: {i_Min = 101; i_Max = 104;} // Rochelle
			case 5: {i_Min = 129; i_Max = 132;} // Bill
			case 6: {i_Min = 164; i_Max = 166;} // Francis
			case 7: {i_Min = 127; i_Max = 131;} // Louis
			case 8: {i_Min = 223; i_Max = 226;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playercriticalhurt") || StrEqual(vocalize,"playerhurtcritical"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 140; i_Max = 147;} // Coach
			case 2: {i_Min = 124; i_Max = 130;} // Nick
			case 3: {i_Min = 115; i_Max = 120;} // Ellis
			case 4: {i_Min = 105; i_Max = 108;} // Rochelle
			case 5: {i_Min = 133; i_Max = 142;} // Bill
			case 6: {i_Min = 167; i_Max = 177;} // Francis
			case 7: {i_Min = 132; i_Max = 136;} // Louis
			case 8: {i_Min = 227; i_Max = 234;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"survivorincapacitatedhurt") || StrEqual(vocalize,"incapacitatedhurt"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 148; i_Max = 151;} // Coach
			case 2: {i_Min = 131; i_Max = 134;} // Nick
			case 3: {i_Min = 121; i_Max = 126;} // Ellis
			case 4: {i_Min = 113; i_Max = 116;} // Rochelle
			case 5: {i_Min = 143; i_Max = 147;} // Bill
			case 6: {i_Min = 178; i_Max = 183;} // Francis
			case 7: {i_Min = 137; i_Max = 139;} // Louis
			case 8: {i_Min = 235; i_Max = 238;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerhelp") || StrEqual(vocalize,"helpincapped") || StrEqual(vocalize,"playerhelpincapped") || StrEqual(vocalize,"playerhelpincapacitated"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 152; i_Max = 167;} // Coach
			case 2: {i_Min = 135; i_Max = 149;} // Nick
			case 3: {i_Min = 127; i_Max = 149;} // Ellis
			case 4: {i_Min = 117; i_Max = 131;} // Rochelle
			case 5: {i_Min = 148; i_Max = 172;} // Bill
			case 6: {i_Min = 184; i_Max = 208;} // Francis
			case 7: {i_Min = 140; i_Max = 153;} // Louis
			case 8: {i_Min = 239; i_Max = 255;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"playerhealing") || StrEqual(vocalize,"covermeheal"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 168; i_Max = 179;} // Coach
			case 2: {i_Min = 150; i_Max = 163;} // Nick
			case 3: {i_Min = 150; i_Max = 159;} // Ellis
			case 4: {i_Min = 132; i_Max = 138;} // Rochelle
			case 5: {i_Min = 173; i_Max = 180;} // Bill
			case 6: {i_Min = 209; i_Max = 222;} // Francis
			case 7: {i_Min = 154; i_Max = 163;} // Louis
			case 8: {i_Min = 266; i_Max = 277;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"relaxedsigh"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 180; i_Max = 183;} // Coach
			case 2: {i_Min = 164; i_Max = 170;} // Nick
			case 3: {i_Min = 160; i_Max = 165;} // Ellis
			case 4: {i_Min = 139; i_Max = 143;} // Rochelle
			case 5: {i_Min = 181; i_Max = 184;} // Bill
			case 6: {i_Min = 223; i_Max = 225;} // Francis
			case 7: {i_Min = 164; i_Max = 166;} // Louis
			case 8: {i_Min = 278; i_Max = 280;} // Zoey
		}
	}
	
	else if(StrEqual(vocalize,"healother"))
	{
		switch (i_Type)
		{
			case 1: {i_Min = 184; i_Max = 190;} // Coach
			case 2: {i_Min = 171; i_Max = 180;} // Nick
			case 3: {i_Min = 166; i_Max = 177;} // Ellis
			case 4: {i_Min = 144; i_Max = 147;} // Rochelle
			case 5: {i_Min = 185; i_Max = 192;} // Bill
			case 6: {i_Min = 226; i_Max = 232;} // Francis
			case 7: {i_Min = 167; i_Max = 171;} // Louis
			case 8: {i_Min = 281; i_Max = 289;} // Zoey
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
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}
	
	{
		// Create scene location and call
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	return Plugin_Handled;
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

public PlayerReload_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize"); 
	} 
	
	switch (i_Type)
	{
		case 1: {i_Min = 111; i_Max = 117;} // Coach
		case 2: {i_Min = 95; i_Max = 101;} // Nick
		case 3: {i_Min = 91; i_Max = 96;} // Ellis
		case 4: {i_Min = 86; i_Max = 89;} // Rochelle
		case 5: {i_Min = 106; i_Max = 108;} // Bill
		case 6: {i_Min = 142; i_Max = 144;} // Francis
		case 7: {i_Min = 106; i_Max = 108;} // Louis
		case 8: {i_Min = 188; i_Max = 191;} // Zoey
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}
	{
		// Create scene location and call
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}	
}
public PlayerHeal_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new victim = GetClientOfUserId(GetEventInt(event, "subject"))
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize"); 
	} 
	
	if (client == victim)
		switch (i_Type)
	{
		case 1: {i_Min = 168; i_Max = 179;} // Coach
		case 2: {i_Min = 150; i_Max = 163;} // Nick
		case 3: {i_Min = 150; i_Max = 159;} // Ellis
		case 4: {i_Min = 132; i_Max = 138;} // Rochelle
		case 5: {i_Min = 173; i_Max = 180;} // Bill
		case 6: {i_Min = 209; i_Max = 222;} // Francis
		case 7: {i_Min = 154; i_Max = 163;} // Louis
		case 8: {i_Min = 266; i_Max = 277;} // Zoey
	}
	else
	switch (i_Type)
	{
		case 1: {i_Min = 184; i_Max = 190;} // Coach
		case 2: {i_Min = 171; i_Max = 180;} // Nick
		case 3: {i_Min = 166; i_Max = 177;} // Ellis
		case 4: {i_Min = 144; i_Max = 147;} // Rochelle
		case 5: {i_Min = 185; i_Max = 192;} // Bill
		case 6: {i_Min = 226; i_Max = 232;} // Francis
		case 7: {i_Min = 167; i_Max = 171;} // Louis
		case 8: {i_Min = 281; i_Max = 290;} // Zoey
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}
	{
		// Create scene location and call
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}	
}

public HealSuccess_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new victim = GetClientOfUserId(GetEventInt(event, "subject"))
	new i_Type, i_Rand, i_Min, i_Max;
	decl String:s_Model[64];
	
	if(client== victim)
		// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", s_Model, 64);
	
	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize"); 
	} 
	
	switch (i_Type)
	{
		case 1: {i_Min = 180; i_Max = 183;} // Coach
		case 2: {i_Min = 164; i_Max = 170;} // Nick
		case 3: {i_Min = 160; i_Max = 165;} // Ellis
		case 4: {i_Min = 139; i_Max = 143;} // Rochelle
		case 5: {i_Min = 181; i_Max = 184;} // Bill
		case 6: {i_Min = 223; i_Max = 225;} // Francis
		case 7: {i_Min = 164; i_Max = 166;} // Louis
		case 8: {i_Min = 278; i_Max = 280;} // Zoey
	}
	i_Rand = GetRandomInt(i_Min, i_Max);
	decl String:s_Temp[40];
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}
	{
		// Create scene location and call
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(client, CustomVoc[75]);
	}
	// Get survivor model
	GetEntPropString(victim, Prop_Data, "m_ModelName", s_Model, 64);
	
	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else { LogError("failed to vocalize"); 
	} 
	
	switch (i_Type)
	{
		case 1: {i_Min = 180; i_Max = 183;} // Coach
		case 2: {i_Min = 164; i_Max = 170;} // Nick
		case 3: {i_Min = 160; i_Max = 165;} // Ellis
		case 4: {i_Min = 139; i_Max = 143;} // Rochelle
		case 5: {i_Min = 181; i_Max = 184;} // Bill
		case 6: {i_Min = 223; i_Max = 225;} // Francis
		case 7: {i_Min = 164; i_Max = 166;} // Louis
		case 8: {i_Min = 278; i_Max = 280;} // Zoey
	}
	
	i_Rand = GetRandomInt(i_Min, i_Max);
	
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}
	{
		// Create scene location and call
		decl String:CustomVoc[75];
		decl String:s_Scene[90];
		Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
		CustomVoc[75] = VocalizeScene(client, s_Scene);
		L4D_MakeClientVocalizeEx(victim, CustomVoc[75]);
	}	
}

