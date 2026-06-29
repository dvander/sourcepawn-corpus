public Plugin:myinfo = 
{
	name = "Surv",
	author = "ivailosp",
	description = "",
	version = "1.0",
	url = "N/A"
}
public PrecacheSurvModel()
{
		PrecacheModel("models/survivors/survivor_teenangst.mdl");
		PrecacheModel("models/survivors/survivor_biker.mdl");
		PrecacheModel("models/survivors/survivor_manager.mdl");
		PrecacheModel("models/survivors/survivor_namvet.mdl");
}

public OnMapStart()
{
	PrecacheSurvModel();
}