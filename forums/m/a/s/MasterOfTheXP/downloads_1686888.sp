#include <sourcemod>
#include <sdktools>

public OnPluginStart() OnBothStart();

public OnMapStart() OnBothStart();

public OnBothStart()
{
    AddFileToDownloadsTable("models/custom/whatever1.mdl");
    AddFileToDownloadsTable("models/custom/whatever2.mdl");
}