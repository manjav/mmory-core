package com.gerantech.mmory.core.battle;


import com.gerantech.mmory.core.scripts.ScriptEngine;
import com.gerantech.mmory.core.exchanges.ExchangeItem;
import com.gerantech.mmory.core.constants.ExchangeType;
import com.gerantech.mmory.core.utils.maps.IntIntMap;
import com.gerantech.mmory.core.constants.ResourceType;

/**
 * Created by ManJav on 2/13/2018.
 */
class Outcome
{
#if java
	static var LOSE_PONT:Int = 3;
	static var WIN_POINT:Int = 8;

	static public function get(battleField:BattleField, type:Int, alliseSide:Int, alliseStar:Int, axisStar:Int) : IntIntMap
	{
		var ret = new IntIntMap();
		if( battleField.friendlyMode > 0 )
    	{
			ret.set(ResourceType.R15_BATTLES_FRIENDLY, 1);
			return ret;
		}

		var alliesGame = battleField.games[alliseSide];
		if( alliesGame.player.isBot() )
			return ret;
		
		// trace("mode:" + battleField.field.mode + " type:" + type);
		var league = alliesGame.arenas.get(alliesGame.player.get_arena(0));

		// points
		var point = getPoint(battleField, type, alliseSide, alliseStar, axisStar);
		if( point != 0 )
			ret.set(ResourceType.R2_POINT, point);
		
		// battle stats
		ret.set(ResourceType.R12_BATTLES, 1);
		ret.set(ResourceType.R30_CHALLENGES, battleField.field.mode + 6);
		if( league.index > 0 )
			ret.set(ResourceType.R17_STARS, alliseStar);
		if( alliseStar > axisStar )
		{
			// num wins
			ret.set(ResourceType.R13_BATTLES_WINS, 1);
			ret.set(ResourceType.R30_CHALLENGES, battleField.field.mode + 1);

			// soft-currency
			var sc = Math.max(0, alliseStar) + Math.min(league.index * 2, Math.max(0, alliesGame.player.get_point() - alliesGame.player.get_softs())) * battleField.field.mode;
			var softs:Int = 2 * cast(sc, Int);
			if( softs != 0 && alliesGame.player.get_battleswins() > 4 )
				ret.set(ResourceType.R3_CURRENCY_SOFT, softs);

			// random book
			var now:Int = Math.round(battleField.now * 0.001);
			var emptySlotsType = getEmptySlots(alliesGame, now);
			if( emptySlotsType.length > 0 )
			{
				var randomEmptySlotIndex = alliesGame.player.get_battleswins() == 0 ? 0 : Math.floor(Math.random() * emptySlotsType.length);
				var emptySlot = alliesGame.exchanger.items.get(emptySlotsType[randomEmptySlotIndex]);
				alliesGame.exchanger.findRandomOutcome(emptySlot, now);
				ret.set(emptySlot.outcome, emptySlot.type);
			}
		}

		return ret;
	}

	static function getPoint(battleField:BattleField, type:Int, alliseSide:Int, alliseStar:Int, axisStar:Int) : Int
	{
		var alliesGame = battleField.games[alliseSide];
		var axisGame = battleField.games[alliseSide == 0 ? 1: 0];
		if( alliesGame.player.get_point() < 0 )
		{
			if( alliseStar > axisStar )
				return alliesGame.player.id % 2 == 0 ? 1 : 2;
			else 
				return 0;
		}

		if( alliseStar == axisStar )
			return 0;

		if( alliesGame.player.get_point() < 20 && alliseStar < axisStar )
			return 0;

		// var diff = alliseStar - axisStar;
		return ScriptEngine.getInt(ScriptEngine.T48_CHALLENGE_REWARDCOEF, type ) * (alliseStar > axisStar ? WIN_POINT : LOSE_PONT);
	}

	static  function getEmptySlots(alliesGame:Game, now:Int) : Array<Int>
	{
		var ret = new Array<Int>();
		var i = 0;
		var k = 0;
		var keys = alliesGame.exchanger.items.keys();
 		while( i < keys.length )
		{
      k = keys[i];
      if (alliesGame.exchanger.items.get(k).category == ExchangeType.C110_BATTLES	&& alliesGame.exchanger.items.get(k).getState(now) == ExchangeItem.CHEST_STATE_EMPTY )
        ret.push(alliesGame.exchanger.items.get(k).type);
      i ++;
    }
		return ret;
	}
#end
}
