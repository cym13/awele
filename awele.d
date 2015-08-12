#!/usr/bin/env rdmd

import std.algorithm;
import std.array;
import std.conv;
import std.range;
import std.stdio;
import std.string;

struct Player {
    string  name;
    uint    points = 0;
    uint[6] holes;

    this(string name, uint number) {
        this.name  = name;
        this.holes = iota(6*number, (6*number)+6).array;
    }
}

struct Game {
    uint[12]  board = [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];
    Player[2] players;
    uint      curr;
    bool      _end = false;

    this(Player p1, Player p2) {
        players = [p1, p2];
        curr = 0;
    }

    uint distribute(uint hole) {
        uint grains = board[hole];

        board[hole] = 0;

        auto receivers = iota(12).cycle[hole+1..$].take(grains);

        foreach (r ; receivers)
            board[r] += 1;

        uint points = 0;
        foreach (uint r ; receivers.retro) {
            if (players[curr].holes[].canFind(r))
                break;

            if (board[r] != 2 && board[r] != 3)
                break;

            points += board[r];
            board[r] = 0;
        }

        players[curr].points += points;
        return points;
    }


    bool isValid(in int move) const {
        if (!players[curr].holes[].canFind(move))
            return false;

        if (board[move] == 0)
            return false;

        // TODO: missing rules

        return true;
    }

    auto swapTurns() {
        curr = curr == 0 ? 1 : 0;
        return curr;
    }

    bool end() {
        // TODO: missing rules

        if (_end)
            return true;

        if (board[].sum < 5)
            return true;

        return false;
    }

    Player winner() const {
        // TODO: missing rules
        return players[0].points > players[1].points ? players[0] : players[1];
    }
}

struct UI {
    void update(in Game game) {
        writeln();
        printBoard(game);
        writeln();

        foreach (i ; [0, 1]) {
            writeln(game.curr == i ? "*" : " ",
                    game.players[i].name,
                    " [", game.players[i].points, "]");
        }

        writeln();
    }

    uint getMove(in Game game) {
        auto player = game.players[game.curr].name;

        int getinput() {
            write("Enter your move ", player, " ");
            return "abcdef".countUntil(readln.chomp).to!int;
        }

        int move = getinput() + (6 * game.curr);
        while (!game.isValid(move)) {
            writeln("Invalid move");

            move = getinput();
        }

        return move;
    }

    void printBoard(in Game game) {
        writeln(game.board);

        if (game.curr == 1)
            write("                  ");
        writeln(" a  b  c  d  e  f");
    }

    Player getPlayer(in uint i) {
        write("Player ", i, " name: ");
        return Player(readln.chomp, i-1);
    }

    void victory(in Game game) {
        writeln();
        update(game);
        writeln();
        writeln("Congratulation ", game.winner.name, " you won!");
    }
}

void main() {
    auto ui   = UI();
    auto game = Game(ui.getPlayer(1),
                     ui.getPlayer(2));

    uint grains_won;
    while (!game.end) {
        ui.update(game);
        grains_won = game.distribute(ui.getMove(game));

        if (grains_won)
            writeln("You won ", grains_won, " points!");

        game.swapTurns();
    }

    ui.victory(game);
}

