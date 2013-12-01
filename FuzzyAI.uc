class FuzzyAI extends UDKBot;
var Pawn Player1;
var Pawn Target;
var Vector NavGoalLocation;
var Vector NextLocationToGoal;
var int tDist;
var float tPercent;
var float BOT_AIMING_EPSILON;


//Seek parameters
var int SEEK_MOVESPEED_BOOST;
var int SEEK_MAX_DIST;
var int SEEK_ENDCLOSE_DIST;
var int SEEK_STARTCLOSE_DIST;
var int SEEK_THREATENED_DIST;

//Flee parameters
var int FLEE_HITCOUNT_FIREBACK;
var int FLEE_CLOSE_TRIGGERATTACK;
var int FLEE_FIGHTBACK_MAXDIST;
var int fleeHitcount;
var bool fleeBoosted;
var bool fleeFightback;

var int PawnHealthLast;
simulated function Tick(float tDelta) {
	
	/*if (IsInState('flee')) {
		//Worldinfo.Game.Broadcast(self,"Tick Fleeeing");
		if (Pawn.Health<PawnHealthLast) {
			PawnHealthLast=Pawn.Health;
			fleeHitcount++;
			Worldinfo.Game.Broadcast(self,"hitcount:"@ fleeHitcount);
			if (fleeHitcount>=FLEE_HITCOUNT_FIREBACK) {
				fleeFightback=true;
			}
		}
	}*/
}

function int M_Lerp(float norm,float a,float b) {
	return a + (norm*(b-a));
}

function GetNextRandomLocation()
{
	//class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,Target.Location);
	class'NavMeshGoal_Random'.static.FindRandom(NavigationHandle, 200);
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle,NextLocationToGoal);
	NavigationHandle.FindPath();
	NavGoalLocation=NavigationHandle.PathCache_GetGoalPoint();
	//NavGoalLocation=Target.Location;//only if following target
	NavigationHandle.SetFinalDestination(NavGoalLocation);
	if(NavigationHandle.PointReachable(NavGoalLocation))
		NextLocationToGoal=NavGoalLocation;
	else
		NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);
}

function GetNextFleeTargetedLocation(Object.Vector targetLocation) {
	class'NavMeshGoal_Random'.static.FindRandom(NavigationHandle, 200);
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle,NextLocationToGoal);
	NavigationHandle.FindPath();
	NavGoalLocation=targetLocation;
	NavigationHandle.SetFinalDestination(NavGoalLocation);
	if(NavigationHandle.PointReachable(NavGoalLocation))
		NextLocationToGoal=NavGoalLocation;
	else
		NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);
}
function SetNextLocationInPath() {
	NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);//checkme
}

function BeginState (name PreviousStateName){
	NavGoalLocation=Pawn.Location;
}

//this event is so touchy with parameters...
event TakeDamage(int amtDmg,Controller EventInstigator, Object.Vector HitLocation, Object.Vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser) {
	Worldinfo.Game.Broadcast(self,"TD:"@ EventInstigator);
}

function SetAimRot(Pawn p,Object.Vector aim) {
    local Rotator final_rot;
	final_rot = Rotator(Normal(aim)); //Look straight at aim
    p.SetViewRotation(final_rot);
}


auto state Wander
{
	event SeePlayer(Pawn SeenPlayer)
	{
		Target = SeenPlayer;
		GetStateName();
		if(!IsInState('Seek')) {
			Worldinfo.Game.Broadcast(self,"Seeking");
			GotoState('Seek');
		}
	}
	Begin:
		Pawn.SetMovementPhysics();
		//WaitForLanding();
		Worldinfo.Game.Broadcast(self, "begin");
	   if(Pawn.ReachedPoint(NavGoalLocation, None)){
			GetNextRandomLocation();
			Worldinfo.Game.Broadcast(self, "none");
	   } else {
			GetNextRandomLocation();//newly added
			MoveTo(NextLocationToGoal);
			SetNextLocationInPath();
			Worldinfo.Game.Broadcast(self, "next");
	   }
	DoneWander:

	   Sleep(0.1);
	   Worldinfo.Game.Broadcast(self, "done");
	   goto('Begin');

}
/*
 if(Pawn.Health<=Max(MinHealth,MaxHealth))
 GotoState('Flee');
 if(Pawn.Health>MaxHealth)
 goto('Begin');
*/

state Seek
{
 Begin:
 tDist=VSize(Pawn.Location-Target.Location); //Set the distance variable
 
	if(tDist>SEEK_MAX_DIST) { //Too far away, use boosted speed
		if(fleeBoosted==false) {
			Worldinfo.Game.Broadcast(self,"Pawn speed boost");
			Pawn.GroundSpeed+=SEEK_MOVESPEED_BOOST;
			fleeBoosted=true; //Set a variable so we know not to call continuously
		}
	} else if (tDist>min(SEEK_ENDCLOSE_DIST,SEEK_STARTCLOSE_DIST)) {
		tPercent=abs(tDist-SEEK_ENDCLOSE_DIST)/(SEEK_STARTCLOSE_DIST-SEEK_ENDCLOSE_DIST);
		Pawn.GroundSpeed=M_Lerp(tPercent,200,500); //dynamically change groundspeed to smooth in arrival. simple
		MoveTo(SEEK_ENDCLOSE_DIST*Normal(Pawn.Location-Target.Location)+Target.Location);
	} else if (tDist<max(SEEK_ENDCLOSE_DIST,SEEK_STARTCLOSE_DIST)) {
		Pawn.GroundSpeed=500;
		MoveTo(SEEK_ENDCLOSE_DIST*Normal(Pawn.Location-Target.Location)+Target.Location);
	}
	SetAimRot(Pawn,Target.Location-Pawn.Location);
	if (tDist<SEEK_THREATENED_DIST) {
		Worldinfo.Game.Broadcast(self,"Bot threatened@proximity : Gone to Flee");
		//Pawn.FireWeaponAt(Target);
		GotoState('Flee');
	}
	/*
	if (tDist< && ) {

	}
	if (tDist<min(SEEK_ENDCLOSE_DIST,SEEK_STARTCLOSE_DIST)) {

		//FaceMoveTarget(Target);
		//Aimat Target
	}*/
	/*if (Target.IsAimingAt(Pawn,0.8) && VSize(Target.Velocity)>100 && tDist<SEEK_THREATENED_DIST) {
		
		GotoState('Flee');
	}
	*/
	
	/*
	if ((Target.Velocity dot Normal(Pawn.Location-Target.Location))>0.5) { //not working
		//Enemy Target moving toward me, must flee
		Worldinfo.Game.Broadcast(self,"Pawn Fleeing target from startling advancement");
		GotoState('Flee');
	}*/
	Sleep(0.1);
	Goto('Begin');
}


 /*if(Pawn.Health<=Min(MinHealth,MaxHealth)){
 Pawn.Health+=100;
 Worldinfo.Game.Broadcast(self, Pawn.Health);
 }
 if(Pawn.Health<=Max(MinHealth,MaxHealth))
 goto('Begin');
 if(Pawn.Health>MaxHealth)
 GotoState('Seek');*/
state Flee
{
Begin:
	tDist=VSize(Target.Location-Pawn.Location);
	if (tDist<=min(FLEE_CLOSE_TRIGGERATTACK,FLEE_FIGHTBACK_MAXDIST)) {
		//TRIGGER ATTACK

		//FireWeaponAt(Target);
		//FaceMoveTarget(Target);
		
		Worldinfo.Game.Broadcast(self,"Flee->Seek : Fightback");
		Pawn.BotFire(true); //Set attacking because player is following bot around closely
		GotoState('Seek');

	}
	if (tDist>=max(FLEE_CLOSE_TRIGGERATTACK,FLEE_FIGHTBACK_MAXDIST)) {
		//out of range
	} else {
		//within fightback-maxdist
		if (fleeFightback) {
			Worldinfo.Game.Broadcast(self,"Flee->Seek : Fightback");
			GotoState('Seek');
		}
	}
	
	NavGoalLocation=(Pawn.Location + ((Pawn.Location-Target.Location)/(VSize(Pawn.Location-Target.Location)))*200);
	//escape by using navpoints
	if ( Pawn.ReachedPoint(NavGoalLocation,None) ) {
		GetNextRandomLocation();
		Worldinfo.Game.Broadcast(self, "none flee");
	} else {
		GetNextFleeTargetedLocation(NavGoalLocation);
		MoveTo(NextLocationToGoal);
		SetNextLocationInPath();
		Worldinfo.Game.Broadcast(self, "next flee goal");
	}
	Sleep(0.1);
	Goto('Begin');
}


DefaultProperties
{
//All capitals to me represents something not to change the value of but to read-only *Rule of programming (for me) that works in all languages, helps cross language compatibility and mental-process
SEEK_MOVESPEED_BOOST=100
SEEK_MAX_DIST=800
SEEK_STARTCLOSE_DIST=500
SEEK_ENDCLOSE_DIST=300
SEEK_THREATENED_DIST=120

FLEE_HITCOUNT_FIREBACK=2
FLEE_CLOSE_TRIGGERATTACK=300
FLEE_FIGHTBACK_MAXDIST=500 //only recourse action if you are within quick-response fighting distance, not across the map
fleeHitcount=0
fleeBoosted=false
fleeFightback=false

BOT_AIMING_EPSILON=0.8
}