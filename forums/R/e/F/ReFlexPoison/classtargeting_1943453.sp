#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Class Target Filters"
#define PLUGIN_VERSION "1.3"

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Class Target Filters",
	author = "ReFlexPoison",
	description = "Add target filters for TF2 classes",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErrMax)
{
	decl String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));

	if(!StrEqual(strGame, "tf"))
	{
		Format(strError, iErrMax, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_classtarget_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	AddMultiTargetFilter("@scout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@scouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!scout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!scouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@redscout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@scouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!redscout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!redscouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@bluscout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@bluscouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!bluscout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!bluscouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@bluescout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@bluescouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!bluescout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!bluescouts", FilterClasses, "all but scouts", false);

	AddMultiTargetFilter("@soldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@soldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!soldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!soldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@redsoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@redsoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!redsoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!redsoldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@blusoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@blusoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!blusoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!blusoldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@bluesoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@bluesoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!bluesoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!bluesoldiers", FilterClasses, "all but soldiers", false);

	AddMultiTargetFilter("@pyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@pyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!pyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!pyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@redpyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@redpyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!redpyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!redpyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@blupyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@blupyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!blupyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!blupyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@bluepyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@bluepyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!bluepyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!bluepyros", FilterClasses, "all but pyros", false);

	AddMultiTargetFilter("@demo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!demo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@reddemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!reddemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@bludemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!bludemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@bluedemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!bluedemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemomen", FilterClasses, "all but demomen", false);

	AddMultiTargetFilter("@heavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@heavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!heavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!heavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@redheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@redheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!redheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!redheavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@bluheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@bluheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!bluheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!bluheavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@blueheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@blueheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!blueheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!blueheavies", FilterClasses, "all but heavies", false);

	AddMultiTargetFilter("@engy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!engy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@redengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!redengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@bluengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!bluengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@blueengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!blueengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengineers", FilterClasses, "all but engineers", false);

	AddMultiTargetFilter("@medic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@medics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!medic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!medics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@redmedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@redmedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!redmedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!redmedics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@blumedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@blumedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!blumedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!blumedics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@bluemedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@bluemedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!bluemedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!bluemedics", FilterClasses, "all but medics", false);

	AddMultiTargetFilter("@sniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@snipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!sniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!snipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@redsniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@redsnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!redsniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!redsnipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@blusniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@blusnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!blusniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!blusnipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@bluesniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@bluesnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!bluesniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!bluesnipers", FilterClasses, "all but snipers", false);

	AddMultiTargetFilter("@spy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@spies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!spy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!spies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@redspy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@redspies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!redspy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!redspies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@bluspy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@bluspies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!bluspy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!bluspies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@bluespy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@bluespies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!bluespy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!bluespies", FilterClasses, "all but spies", false);
}

public OnPluginEnd()
{
	RemoveMultiTargetFilter("@scout", FilterClasses);
	RemoveMultiTargetFilter("@scouts", FilterClasses);
	RemoveMultiTargetFilter("@!scout", FilterClasses);
	RemoveMultiTargetFilter("@!scouts", FilterClasses);
	RemoveMultiTargetFilter("@redscout", FilterClasses);
	RemoveMultiTargetFilter("@scouts", FilterClasses);
	RemoveMultiTargetFilter("@!redscout", FilterClasses);
	RemoveMultiTargetFilter("@!redscouts", FilterClasses);
	RemoveMultiTargetFilter("@bluscout", FilterClasses);
	RemoveMultiTargetFilter("@bluscouts", FilterClasses);
	RemoveMultiTargetFilter("@!bluscout", FilterClasses);
	RemoveMultiTargetFilter("@!bluscouts", FilterClasses);
	RemoveMultiTargetFilter("@bluescout", FilterClasses);
	RemoveMultiTargetFilter("@bluescouts", FilterClasses);
	RemoveMultiTargetFilter("@!bluescout", FilterClasses);
	RemoveMultiTargetFilter("@!bluescouts", FilterClasses);

	RemoveMultiTargetFilter("@soldier", FilterClasses);
	RemoveMultiTargetFilter("@soldiers", FilterClasses);
	RemoveMultiTargetFilter("@!soldier", FilterClasses);
	RemoveMultiTargetFilter("@!soldiers", FilterClasses);
	RemoveMultiTargetFilter("@redsoldier", FilterClasses);
	RemoveMultiTargetFilter("@redsoldiers", FilterClasses);
	RemoveMultiTargetFilter("@!redsoldier", FilterClasses);
	RemoveMultiTargetFilter("@!redsoldiers", FilterClasses);
	RemoveMultiTargetFilter("@blusoldier", FilterClasses);
	RemoveMultiTargetFilter("@blusoldiers", FilterClasses);
	RemoveMultiTargetFilter("@!blusoldier", FilterClasses);
	RemoveMultiTargetFilter("@!blusoldiers", FilterClasses);
	RemoveMultiTargetFilter("@bluesoldier", FilterClasses);
	RemoveMultiTargetFilter("@bluesoldiers", FilterClasses);
	RemoveMultiTargetFilter("@!bluesoldier", FilterClasses);
	RemoveMultiTargetFilter("@!bluesoldiers", FilterClasses);

	RemoveMultiTargetFilter("@pyro", FilterClasses);
	RemoveMultiTargetFilter("@pyros", FilterClasses);
	RemoveMultiTargetFilter("@!pyro", FilterClasses);
	RemoveMultiTargetFilter("@!pyros", FilterClasses);
	RemoveMultiTargetFilter("@redpyro", FilterClasses);
	RemoveMultiTargetFilter("@redpyros", FilterClasses);
	RemoveMultiTargetFilter("@!redpyro", FilterClasses);
	RemoveMultiTargetFilter("@!redpyros", FilterClasses);
	RemoveMultiTargetFilter("@blupyro", FilterClasses);
	RemoveMultiTargetFilter("@blupyros", FilterClasses);
	RemoveMultiTargetFilter("@!blupyro", FilterClasses);
	RemoveMultiTargetFilter("@!blupyros", FilterClasses);
	RemoveMultiTargetFilter("@bluepyro", FilterClasses);
	RemoveMultiTargetFilter("@bluepyros", FilterClasses);
	RemoveMultiTargetFilter("@!bluepyro", FilterClasses);
	RemoveMultiTargetFilter("@!bluepyros", FilterClasses);

	RemoveMultiTargetFilter("@demo", FilterClasses);
	RemoveMultiTargetFilter("@demos", FilterClasses);
	RemoveMultiTargetFilter("@demoman", FilterClasses);
	RemoveMultiTargetFilter("@demomans", FilterClasses);
	RemoveMultiTargetFilter("@demomen", FilterClasses);
	RemoveMultiTargetFilter("@!demo", FilterClasses);
	RemoveMultiTargetFilter("@!demos", FilterClasses);
	RemoveMultiTargetFilter("@!demoman", FilterClasses);
	RemoveMultiTargetFilter("@!demomans", FilterClasses);
	RemoveMultiTargetFilter("@!demomen", FilterClasses);
	RemoveMultiTargetFilter("@reddemo", FilterClasses);
	RemoveMultiTargetFilter("@reddemos", FilterClasses);
	RemoveMultiTargetFilter("@reddemoman", FilterClasses);
	RemoveMultiTargetFilter("@reddemomans", FilterClasses);
	RemoveMultiTargetFilter("@reddemomen", FilterClasses);
	RemoveMultiTargetFilter("@!reddemo", FilterClasses);
	RemoveMultiTargetFilter("@!reddemos", FilterClasses);
	RemoveMultiTargetFilter("@!reddemoman", FilterClasses);
	RemoveMultiTargetFilter("@!reddemomans", FilterClasses);
	RemoveMultiTargetFilter("@!reddemomen", FilterClasses);
	RemoveMultiTargetFilter("@bludemo", FilterClasses);
	RemoveMultiTargetFilter("@bludemos", FilterClasses);
	RemoveMultiTargetFilter("@bludemoman", FilterClasses);
	RemoveMultiTargetFilter("@bludemomans", FilterClasses);
	RemoveMultiTargetFilter("@bludemomen", FilterClasses);
	RemoveMultiTargetFilter("@!bludemo", FilterClasses);
	RemoveMultiTargetFilter("@!bludemos", FilterClasses);
	RemoveMultiTargetFilter("@!bludemoman", FilterClasses);
	RemoveMultiTargetFilter("@!bludemomans", FilterClasses);
	RemoveMultiTargetFilter("@!bludemomen", FilterClasses);
	RemoveMultiTargetFilter("@bluedemo", FilterClasses);
	RemoveMultiTargetFilter("@bluedemos", FilterClasses);
	RemoveMultiTargetFilter("@bluedemoman", FilterClasses);
	RemoveMultiTargetFilter("@bluedemomans", FilterClasses);
	RemoveMultiTargetFilter("@bluedemomen", FilterClasses);
	RemoveMultiTargetFilter("@!bluedemo", FilterClasses);
	RemoveMultiTargetFilter("@!bluedemos", FilterClasses);
	RemoveMultiTargetFilter("@!bluedemoman", FilterClasses);
	RemoveMultiTargetFilter("@!bluedemomans", FilterClasses);
	RemoveMultiTargetFilter("@!bluedemomen", FilterClasses);

	RemoveMultiTargetFilter("@heavy", FilterClasses);
	RemoveMultiTargetFilter("@heavies", FilterClasses);
	RemoveMultiTargetFilter("@!heavy", FilterClasses);
	RemoveMultiTargetFilter("@!heavies", FilterClasses);
	RemoveMultiTargetFilter("@redheavy", FilterClasses);
	RemoveMultiTargetFilter("@redheavies", FilterClasses);
	RemoveMultiTargetFilter("@!redheavy", FilterClasses);
	RemoveMultiTargetFilter("@!redheavies", FilterClasses);
	RemoveMultiTargetFilter("@bluheavy", FilterClasses);
	RemoveMultiTargetFilter("@bluheavies", FilterClasses);
	RemoveMultiTargetFilter("@!bluheavy", FilterClasses);
	RemoveMultiTargetFilter("@!bluheavies", FilterClasses);
	RemoveMultiTargetFilter("@blueheavy", FilterClasses);
	RemoveMultiTargetFilter("@blueheavies", FilterClasses);
	RemoveMultiTargetFilter("@!blueheavy", FilterClasses);
	RemoveMultiTargetFilter("@!blueheavies", FilterClasses);

	RemoveMultiTargetFilter("@engy", FilterClasses);
	RemoveMultiTargetFilter("@engys", FilterClasses);
	RemoveMultiTargetFilter("@engineer", FilterClasses);
	RemoveMultiTargetFilter("@engineers", FilterClasses);
	RemoveMultiTargetFilter("@!engy", FilterClasses);
	RemoveMultiTargetFilter("@!engys", FilterClasses);
	RemoveMultiTargetFilter("@!engineer", FilterClasses);
	RemoveMultiTargetFilter("@!engineers", FilterClasses);
	RemoveMultiTargetFilter("@redengy", FilterClasses);
	RemoveMultiTargetFilter("@redengys", FilterClasses);
	RemoveMultiTargetFilter("@redengineer", FilterClasses);
	RemoveMultiTargetFilter("@redengineers", FilterClasses);
	RemoveMultiTargetFilter("@!redengy", FilterClasses);
	RemoveMultiTargetFilter("@!redengys", FilterClasses);
	RemoveMultiTargetFilter("@!redengineer", FilterClasses);
	RemoveMultiTargetFilter("@!redengineers", FilterClasses);
	RemoveMultiTargetFilter("@bluengy", FilterClasses);
	RemoveMultiTargetFilter("@bluengys", FilterClasses);
	RemoveMultiTargetFilter("@bluengineer", FilterClasses);
	RemoveMultiTargetFilter("@bluengineers", FilterClasses);
	RemoveMultiTargetFilter("@!bluengy", FilterClasses);
	RemoveMultiTargetFilter("@!bluengys", FilterClasses);
	RemoveMultiTargetFilter("@!bluengineer", FilterClasses);
	RemoveMultiTargetFilter("@!bluengineers", FilterClasses);
	RemoveMultiTargetFilter("@blueengy", FilterClasses);
	RemoveMultiTargetFilter("@blueengys", FilterClasses);
	RemoveMultiTargetFilter("@blueengineer", FilterClasses);
	RemoveMultiTargetFilter("@blueengineers", FilterClasses);
	RemoveMultiTargetFilter("@!blueengy", FilterClasses);
	RemoveMultiTargetFilter("@!blueengys", FilterClasses);
	RemoveMultiTargetFilter("@!blueengineer", FilterClasses);
	RemoveMultiTargetFilter("@!blueengineers", FilterClasses);

	RemoveMultiTargetFilter("@medic", FilterClasses);
	RemoveMultiTargetFilter("@medics", FilterClasses);
	RemoveMultiTargetFilter("@!medic", FilterClasses);
	RemoveMultiTargetFilter("@!medics", FilterClasses);
	RemoveMultiTargetFilter("@redmedic", FilterClasses);
	RemoveMultiTargetFilter("@redmedics", FilterClasses);
	RemoveMultiTargetFilter("@!redmedic", FilterClasses);
	RemoveMultiTargetFilter("@!redmedics", FilterClasses);
	RemoveMultiTargetFilter("@blumedic", FilterClasses);
	RemoveMultiTargetFilter("@blumedics", FilterClasses);
	RemoveMultiTargetFilter("@!blumedic", FilterClasses);
	RemoveMultiTargetFilter("@!blumedics", FilterClasses);
	RemoveMultiTargetFilter("@bluemedic", FilterClasses);
	RemoveMultiTargetFilter("@bluemedics", FilterClasses);
	RemoveMultiTargetFilter("@!bluemedic", FilterClasses);
	RemoveMultiTargetFilter("@!bluemedics", FilterClasses);

	RemoveMultiTargetFilter("@sniper", FilterClasses);
	RemoveMultiTargetFilter("@snipers", FilterClasses);
	RemoveMultiTargetFilter("@!sniper", FilterClasses);
	RemoveMultiTargetFilter("@!snipers", FilterClasses);
	RemoveMultiTargetFilter("@redsniper", FilterClasses);
	RemoveMultiTargetFilter("@redsnipers", FilterClasses);
	RemoveMultiTargetFilter("@!redsniper", FilterClasses);
	RemoveMultiTargetFilter("@!redsnipers", FilterClasses);
	RemoveMultiTargetFilter("@blusniper", FilterClasses);
	RemoveMultiTargetFilter("@blusnipers", FilterClasses);
	RemoveMultiTargetFilter("@!blusniper", FilterClasses);
	RemoveMultiTargetFilter("@!blusnipers", FilterClasses);
	RemoveMultiTargetFilter("@bluesniper", FilterClasses);
	RemoveMultiTargetFilter("@bluesnipers", FilterClasses);
	RemoveMultiTargetFilter("@!bluesniper", FilterClasses);
	RemoveMultiTargetFilter("@!bluesnipers", FilterClasses);

	RemoveMultiTargetFilter("@spy", FilterClasses);
	RemoveMultiTargetFilter("@spies", FilterClasses);
	RemoveMultiTargetFilter("@!spy", FilterClasses);
	RemoveMultiTargetFilter("@!spies", FilterClasses);
	RemoveMultiTargetFilter("@redspy", FilterClasses);
	RemoveMultiTargetFilter("@redspies", FilterClasses);
	RemoveMultiTargetFilter("@!redspy", FilterClasses);
	RemoveMultiTargetFilter("@!redspies", FilterClasses);
	RemoveMultiTargetFilter("@bluspy", FilterClasses);
	RemoveMultiTargetFilter("@bluspies", FilterClasses);
	RemoveMultiTargetFilter("@!bluspy", FilterClasses);
	RemoveMultiTargetFilter("@!bluspies", FilterClasses);
	RemoveMultiTargetFilter("@bluespy", FilterClasses);
	RemoveMultiTargetFilter("@bluespies", FilterClasses);
	RemoveMultiTargetFilter("@!bluespy", FilterClasses);
	RemoveMultiTargetFilter("@!bluespies", FilterClasses);
}

public bool:FilterClasses(const String:strPattern[], Handle:hClients)
{
	new bool:bOpposite;
	if(StrContains(strPattern, "!") != -1)
		bOpposite = true;

	new TFClassType:iClass = TFClass_Unknown;
	if(StrContains(strPattern, "sc", false) != -1)
		iClass = TFClass_Scout;
	else if(StrContains(strPattern, "so", false) != -1)
		iClass = TFClass_Soldier;
	else if(StrContains(strPattern, "py", false) != -1)
		iClass = TFClass_Pyro;
	else if(StrContains(strPattern, "de", false) != -1)
		iClass = TFClass_DemoMan;
	else if(StrContains(strPattern, "he", false) != -1)
		iClass = TFClass_Heavy;
	else if(StrContains(strPattern, "en", false) != -1)
		iClass = TFClass_Engineer;
	else if(StrContains(strPattern, "me", false) != -1)
		iClass = TFClass_Medic;
	else if(StrContains(strPattern, "sni", false) != -1)
		iClass = TFClass_Sniper;
	else if(StrContains(strPattern, "sp", false) != -1)
		iClass = TFClass_Spy;

	new iTeam;
	if(StrContains(strPattern, "red", false) != -1)
		iTeam = 2;
	else if(StrContains(strPattern, "blu", false) != -1)
		iTeam = 3;

	for(new i = 1; i <= MaxClients; i ++) if(IsClientInGame(i))
	{
		if(!IsPlayerAlive(i))
			continue;

		if(!bOpposite && TF2_GetPlayerClass(i) != iClass)
			continue;

		if(bOpposite && TF2_GetPlayerClass(i) == iClass)
			continue;

		if(iTeam > 0 && GetClientTeam(i) != iTeam)
			continue;

		PushArrayCell(hClients, i);
	}

	return true;
}