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

    bool starving() const {
        return holes[].sum == 0;
    }
}

struct Game {
    uint[12]  board = [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4];
    Player[2] players;
    uint      curr;

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


    bool valid(in int move) const {
        auto player   = players[curr];
        auto opponent = players[(curr == 0) ? 1 : 0];

        if (!player.holes[].canFind(move))
            return false;

        if (board[move] == 0)
            return false;

        if (opponent.starving &&
           !opponent.holes[].canFind((move+board[move])%12))
            return false;

        return true;
    }

    auto swapTurns() {
        curr = curr == 0 ? 1 : 0;
        return curr;
    }

    bool end() {
        if (players[curr].starving)
            return true;

        if (board[].sum < 5)
            return true;

        return false;
    }

    Player winner() const {
        if (players[].count!(p => p.starving) == 1)
            return players[0].starving ? players[1] : players[0];

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
        while (!game.valid(move)) {
            writeln("Invalid move");

            move = getinput();
        }

        return move;
    }

    void printBoard(in Game game) {
        auto letters() {
            enum entries = "abcdef".split("");
            return game.players[game.curr]
                       .holes[]
                       .map!(x => game.valid(x) ? entries[x%6] : " ");
        }

        void board() {
            game.board[6..12].retro.writeln;
            game.board[0..6].writeln;
        }

        if (game.curr == 0) {
            board;
            write(" ");
            letters.joiner("  ")
                   .writeln;
        }
        else {
            write(" ");
            letters.retro
                   .map!toUpper
                   .joiner("  ")
                   .writeln;
            board;
        }
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

    void pointsAlert(uint grainsWon) {
        writeln("You won ", grainsWon, " points!");
    }
}

void main() {
    auto ui   = UI();
    auto game = Game(ui.getPlayer(1),
                     ui.getPlayer(2));

    uint grainsWon;
    while (!game.end) {
        ui.update(game);
        grainsWon = game.distribute(ui.getMove(game));

        if (grainsWon)
            ui.pointsAlert(grainsWon);

        game.swapTurns();
    }

    foreach (p ; game.players)
        p.points += p.holes[].sum;

    ui.victory(game);
}
