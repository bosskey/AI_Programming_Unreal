class FinalRoamAI extends UDKBot;
var Pawn Target; //var Pawn Player1;
var Vector NavGoalLocation;
var Vector NextLocationToGoal;
var int tDist;
var float tPercent;
var float tTime;
var float tDot;
var int discontent;

//patrol vars
var int PATROL_STARTRANGE_DISTMAX;

//ranged vars
var int RANGED_PROXIMITY_DISTMAX;
var int RANGED_OBSERVE_DIST;
var float RANGED_AIM_EPSILON;

//attack vars
var int ATTACK_FIREDIST_MAX;
var float ATTACK_FIRESTOP_TIMELOST;
var int ATTACK_MINHEALTH;
var int ATTACK_MINDIST_TOTARGET;
var int ATTACK_MAXDIST_TOTARGET;

var int FLEE_MAXDIST_FAR;
var float FLEE_DOTVEL_MAX;

//visible vars
var float Visible_timeCount;
var bool Visible_lostSight;
var float lastSeeTargetTime;

//Aim lock vars
var Pawn AIMLOCK_TARGET;
var Pawn AIMLOCK_PAWN;
var bool AIMLOCK_ON;

//I knew about Dot product before this class, its amazing what math does for you.
function float DotDir(Object.Vector norm, Object.Vector vel) { return norm Dot vel; }

function bool IsAimedAt(Pawn me,Pawn target,float epsilon) {
	return (DotDir(Normal(Vector(me.Rotation)),Normal(target.Location-me.Location))>=epsilon);
}

//simple Linear interpolation function
function int M_Lerp(float norm,float a,float b) { return a + (norm*(b-a)); }

//Simple analogue to navhandle point reachable, useful for logical functions below
function bool IsPointReachable(Object.Vector point) {return NavigationHandle.PointReachable(point);}

function GetNextRandomLocation()
{
	//class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,Target.Location);
	class'NavMeshGoal_Random'.static.FindRandom(NavigationHandle, 200);
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle,NextLocationToGoal);
	NavigationHandle.FindPath();
	NavGoalLocation=NavigationHandle.PathCache_GetGoalPoint();
	//NavGoalLocation=Target.Location;//only if following target
	NavigationHandle.SetFinalDestination(NavGoalLocation);
	if(IsPointReachable(NavGoalLocation))
		NextLocationToGoal=NavGoalLocation;
	else
		NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);
}

function GetNextTargetedLocation(Object.Vector targetLocation) {
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,targetLocation);
	//class'NavMeshGoal_Random'.static.FindRandom(NavigationHandle, 200);
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle,targetLocation);
	NavigationHandle.FindPath();
	NavGoalLocation=targetLocation;
	NavigationHandle.SetFinalDestination(NavGoalLocation);
	if(IsPointReachable(NavGoalLocation))
		NextLocationToGoal=NavGoalLocation;
	else
		NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);
}

function bool FindPathToActor(Actor target) {
	class'NavMeshPath_Toward'.static.TowardGoal(NavigationHandle,target);
	class'NavMeshGoal_At'.static.AtActor(NavigationHandle,target,30);
	return NavigationHandle.FindPath();
}

function SetNextLocationInPath() {
	NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);//checkme
}

function BeginState (name PreviousStateName){
	NavGoalLocation=Pawn.Location;
	//Pawn.IsEnemyBot=true;
}

function SetAimRot(Pawn p,Object.Vector aim) {
    local Rotator final_rot;
	final_rot = Rotator(Normal(aim)); //Look straight at aim
    p.SetViewRotation(final_rot);
}

function float TimeSinceS(float timeOrigin) {UnClock(tTime);return (tTime-timeOrigin)/(1000.0f);}
function float Visible_TimeSinceLastViewed() {if (Visible_lostSight) {return TimeSinceS(lastSeeTargetTime);	}	return -1.0f;}

simulated function Tick(float tDelta) {
	if (!Visible_lostSight) {
		if (TimeSinceS(lastSeeTargetTime)>0.5f) { //lost sight for half a second, turn on lost sight bool
			Visible_lostSight=true;
			Visible_timeCount=0.0f;
		}
	}
}


event SeePlayer(Pawn SeenPlayer)
{
	if (SeenPlayer.IsAliveAndWell() && SeenPlayer.IsPlayerPawn()) {
		Target = SeenPlayer;
		if (Visible_lostSight==true) { Visible_lostSight=false; } //Set vision lost bool to false, we have vision again.
		if (lastSeeTargetTime>0.0f) {
			Visible_timeCount= Visible_timeCount+TimeSinceS(lastSeeTargetTime);
		}
		//local float timecount=TimeSince(lastSeeTargetTime);

		UnClock(lastSeeTargetTime); //Update this time variable.
	}
}

auto state Patrol
{
	Begin:
		//Pawn.SetMovementPhysics();
		//WaitForLanding();
		
		//Check if need to go to ranged.
		if (Visible_timeCount>0.5f) { //if seen target for atleast 1 seconds
			tDist=VSize(Pawn.Location-Target.Location);
			if (tDist<PATROL_STARTRANGE_DISTMAX) {
				Worldinfo.Game.Broadcast(self,"R:Patrol->Ranged: Seen + dist<rangemax");
				GotoState('Ranged');
			}
		}

		//find random point to move to as part of patrol
		if(Pawn.ReachedPoint(NavGoalLocation, None)){
			GetNextRandomLocation();
		} else {
			GetNextRandomLocation();
			MoveTo(NextLocationToGoal);
			SetNextLocationInPath();
		}
	
	//return to begin
	Sleep(0.1);
	goto('Begin');
}

state Ranged {
	Begin:
		tDist=VSize(Target.Location-Pawn.Location);
		tDot=DotDir(Normal(Target.Location-Pawn.Location),Target.Velocity);
		if ( tDist<RANGED_PROXIMITY_DISTMAX && (tDot<0.0f && IsAimedAt(Target,Pawn,RANGED_AIM_EPSILON)) && Pawn.Health>ATTACK_MINHEALTH) {
			//target is within radius and is still advancing towards bot.
			Worldinfo.Game.Broadcast(self,"R:Ranged->Attack: dot-advance + dist<distmax");
			GotoState('Attack');
		}
		
		//Get left or right of pawn.location and is not 
		//NavGoalLocation=Pawn.Location
		NavGoalLocation=Target.Location+Normal(Pawn.Location-Target.Location)*RANGED_OBSERVE_DIST;
		
		if ( Pawn.ReachedPoint(NavGoalLocation,None) ) {
			GetNextTargetedLocation(NavGoalLocation);
			//Worldinfo.Game.Broadcast(self, "none flee");
		} else {
			GetNextTargetedLocation(NavGoalLocation);
			MoveTo(NextLocationToGoal,Target);
			SetNextLocationInPath();
		}
		//NavGoalLocation=(Pawn.Location 
	//modes of ranged, all have a target.
	SetAimRot(Pawn,Target.Location-Pawn.Location);
	Sleep(0.1);
	goto('Begin');
}

state Attack {
 Begin:
	tDist=VSize(Pawn.Location-Target.Location); //Set the distance variable
	if (tDist<ATTACK_FIREDIST_MAX) { //start firing if distance less than max
		//Pawn.BotFire(true);
		Pawn.StartFire(0);
		//SetAimLock(Pawn,Target);
	}
	if (Visible_TimeSinceLastViewed()>ATTACK_FIRESTOP_TIMELOST) { //stop firing if enemy not visible for more than half a second
		Pawn.StopFire(0);
	}
 	//SetAimRot(Pawn,Target.Location-Pawn.Location);
	
	if (!Target.IsAliveAndWell()) { //Target.Health<=0) { //If target dead, continue patrolling
		Target=None;
		//Pawn.BotFire(false);
		Pawn.StopFire(0);
		Worldinfo.Game.Broadcast(self,"R:Attack->Patrol: Target is dead");
		GotoState('Patrol');
	}
	
	if (Pawn.Health<ATTACK_MINHEALTH) { //check if need to flee from damage
		//Pawn.BotFire(false);
		Pawn.StopFire(0);
		Worldinfo.Game.Broadcast(self,"R:Attack->Flee: Health too low to attack");
		GotoState('Flee');
	}
	
	if (tDist<ATTACK_MINDIST_TOTARGET) {
		//MoveTo(Target.Location+ Normal(Pawn.Location-Target.Location)*(ATTACK_MAXDIST_TOTARGET-ATTACK_MINDIST_TOTARGET)/2);
		if (NavigationHandle.ActorReachable(Target)) {
			MoveToward(Target,Target);
		}
		else if(FindPathToActor(Target)) {
			NavigationHandle.SetFinalDestination(Target.Location);
			if (NavigationHandle.GetNextMoveLocation(NextLocationToGoal,ATTACK_MINDIST_TOTARGET)) {
				MoveTo(NextLocationToGoal,Target);
			}
		}
	}
	else if (tDist<ATTACK_MAXDIST_TOTARGET) {
		//do nothing or dodge around a bit.
	}
	else if (tDist>ATTACK_MAXDIST_TOTARGET) {
		if (NavigationHandle.ActorReachable(Target)) {
			MoveToward(Target,Target);
		}
		else if(FindPathToActor(Target)) {
			NavigationHandle.SetFinalDestination(Target.Location);
			if (NavigationHandle.GetNextMoveLocation(NextLocationToGoal,Pawn.GetCollisionRadius()+10)) {
				MoveTo(NextLocationToGoal,Target);
			}
		}
	}

	SetAimRot(Pawn,Target.Location-Pawn.Location);
	Sleep(0.1);
	Goto('Begin');
}

//Pawn.BotFire(bool)
state Flee
{
Begin:
	tDist=VSize(Target.Location-Pawn.Location);
	tDot=DotDir(Normal(Pawn.Location-Target.Location),Normal(Target.Velocity));
	//Check if we can go back to patrol
	if (tDist>FLEE_MAXDIST_FAR && tDot<FLEE_DOTVEL_MAX) { //past far distance and enemy is not moving towards bot
		Worldinfo.Game.Broadcast(self,"R:Flee->Patrol: Far dist + no enemy advancement");
		GotoState('Patrol');
	}
	
	NavGoalLocation=(Pawn.Location + Normal(Pawn.Location-Target.Location)*100);
	//flee by using navpoints
	
	if ( Pawn.ReachedPoint(NavGoalLocation,None) ) {
		GetNextTargetedLocation(NavGoalLocation);
	} else {
		GetNextTargetedLocation(NavGoalLocation);
		MoveTo(NextLocationToGoal);
		SetNextLocationInPath();
	}
	Sleep(0.1);
	Goto('Begin');
}


DefaultProperties
{
//All capitals to me represents something not to change the value of but to read-only *Rule of programming (for me) that works in all languages, helps cross language compatibility and mental-process

//PATROL vars
PATROL_STARTRANGE_DISTMAX=800

//RANGED vars
RANGED_PROXIMITY_DISTMAX=450
RANGED_OBSERVE_DIST=600
RANGED_AIM_EPSILON=0.6f

//ATTACK vars
ATTACK_FIREDIST_MAX=400
ATTACK_FIRESTOP_TIMELOST=0.5f
ATTACK_MINHEALTH=50
ATTACK_MINDIST_TOTARGET=100
ATTACK_MAXDIST_TOTARGET=300

//FLEE vars
FLEE_MAXDIST_FAR=500
FLEE_DOTVEL_MAX=0.1f

//visible vars
Visible_lostSight=false
Visible_timeCount=0.0f
lastSeeTargetTime=-1.0f
}