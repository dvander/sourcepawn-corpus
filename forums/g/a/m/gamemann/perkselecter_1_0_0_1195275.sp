#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "perk selecter 1.0.0",
	author = "gamemann",'
	description = "allows you to select perks",
	version = "1.0.0",
	url = "http://games223.com/"
};

//SURVIVORS ++++++++++++++++

//handles
//perks
new Handle:quikster = INVALID_HANDLE;
new Handle:sharpshooter = INVALID_HANDLE;
new Handle:heavy = INVALID_HANDLE;
new Handle:medic = INVALID_HANDLE;
new Handle:commando = INVALID_HANDLE;
new Handle:demo = INVALID_HANDLE;
new Handle:fire = INVALID_HANDLE;


//other
new Handle:PerkSelecter = INVALID_HANDLE;
new Handle:AllowRepick = INVALID_HANDLE;

//types 
new Handle:marine = INVALID_HANDLE;	//very good powerful person
new Handle:leader = INVALID_HANDLE;	//lead survivor bots
new Handle:commander = INVALID_HANDLE;		//very good at commanding people to go places
new Handle:hunter = INVALID_HANDLE;	//calm and patiant and can kill zombies from far distances

//powerups
new Handle:1 = INVALID_HANDLE;	//better accurcy
new Hnadle:2 = INVALID_HANDLE;	//more damage
new Handle:3 = INVALID_HANDLE;	//run faster
new Handle:4 = INVALID_HANDLE;	//more health

//zombie killers
new Handle:Hunter = INVALID_HANDLE;	//better at hunter
new Handle:Boomer = INVALID_HANDLE;	//better at boomber
new Handle:Smoker = INVALID_HANDLE;	//better at smoker
new Handle:Charger = INVALID_HANDLE;	//better at charger
new Handle:Spitter = INVALID_HANDLE;	//better at spitter
new Handle:Tank = INVALID_HANDLE;	//better at tank
new Handle:Witch = INVALID_HANDLE;	//better at witch
new Handle:Jockey = INVALID_HANDLE;	//better at jockey
new Handle:Infected = INVALID_HANDLE;	//better at infected


//INFECTED ++++++++++++++++++
//not out yet!!!

//now for the finding convars
//perks

//quikster

//sharpshooter

//heavy

//medic

//commando

//demo

//fire


//types

//marine

//leader

//commander

//hunter


//powerups

// 1

// 2

// 3

// 4


//zombie killers

//hunter

//boomer

//smoker

//charger

//spitter

//tank

//witch

//jockey

//infected



