uses crt;
type
    entity = record
        id, health, x, y, dx, dy, color: integer;
        isActive: boolean;
    end;
var
    //player stuff
    playerX, playerY, playerFrame: integer;
    //entity stuff
      //bIndex, ebIndex: bullet index
      //oldY: enemies' old y position for enemies
      //randomIdx: random index for enemies chosen to shoot
      //rngRoll: if above certain value, confirm to make the enemy shoot
    bIndex, ebIndex, enemyCount, eBulletCount, oldY: integer;
    randomIdx, rngRoll: integer;
    //game vars
      //gametime: amount of "time" the game is running
      //gamestate: -1: game end, 0: running, 1: win, 2: defeat (-1 life), 4: not running
      //moveinterval: enemies' movement rate (global)
      //shootinterval: enemies' shoot rate (global)
      //state: enemies' movement state (global)
      //sel: menu selection
      //code: only exists because string to integer needs it
      //loadmode: stages of loading save (0: PLAYER, 1: ENEMIES, 2: PLAYERBULLET, 3: ENEMYBULLET)
    t: text;
    lives, score, highscore, gametime, gamestate, state: integer;
    moveinterval, shootinterval, i, j, m, countdown, sel, code: integer;
    loadmode: integer;
    scorename, temp, k, l: string; //name for high score
    newBest, show_menuHighscore: boolean;
    enemies: array[0..54] of entity;
    bullet: array[0..1] of entity; //player bullet
    enemyBullet: array[0..10] of entity;

    isPaused: boolean;
    ch: char;

procedure spawn_playerBullet();
var
    indx: integer; //index mod 2
begin
    indx := bIndex mod 2;
    if (not bullet[indx].isActive) then
    begin
        bullet[indx].x := playerX;
        bullet[indx].y := playerY - 3;
        bullet[indx].color := lightgreen;

        bullet[indx].isActive := true;
        bIndex := bIndex + 1;
    end;
end;

procedure spawn_enemyBullet(posx, posy: integer);
var
   indx: integer; //index mod 11
begin
    indx := ebIndex mod 11;
    if (not enemyBullet[indx].isActive) then
    begin
        enemyBullet[indx].x := posx;
        enemyBullet[indx].y := posy;

        enemyBullet[indx].isActive := true;
        ebIndex := ebIndex + 1;
    end;
end;

procedure spawn_enemies(idx, id, posx, posy: integer);
begin
    enemies[idx].id := id;
    enemies[idx].x := posx;
    enemies[idx].y := posy;

    if id = 1 then //@
    begin
        enemies[idx].health := 1;
    end
    else if id = 2 then //&
    begin
        enemies[idx].health := 2;
    end
    else if id = 3 then //diamond
    begin
        enemies[idx].health := 5;
    end;

    enemies[idx].isActive := true;
    enemyCount := enemyCount + 1;
end;

procedure getRandomIndex();  //get a random active enemy index
begin
    randomIdx := random(54);

    repeat
    begin
        randomIdx := random(54);
    end;
    until enemies[randomIdx].isActive;
end;

procedure refresh_game();
begin
    randomize;
    playerX := 50;
    playerY := 24;
    bullet[0].isActive := false; bullet[1].isActive := false;

    for i := 0 to 10 do
    begin
        enemyBullet[i].isActive := false;
    end;
end;

procedure newEnemies(); //also reset enemies after killing all
begin
    for i := 0 to 54 do
    begin
        if (i <= 10) then
       begin
            spawn_enemies(i, 1, 9 + (i * 4), 13);
        end
        else if (i > 10) and (i <= 21) then
        begin
            spawn_enemies(i, 1, 9 + ((i - 11) * 4), 11);
        end
        else if (i > 21) and (i <= 32) then
        begin
            spawn_enemies(i, 2, 9 + ((i - 22) * 4), 9);
        end
        else if (i > 32) and (i <= 43) then
        begin
            spawn_enemies(i, 2, 9 + ((i - 33) * 4), 7);
        end
        else
            spawn_enemies(i, 3, 9 + ((i - 44) * 4), 4);
    end;
end;

procedure resetGameVars();
begin
    lives := 3;

    playerX := 50;
    playerY := 24;

    moveinterval := 12;
    shootinterval := 10;

    countdown := 4;

    for i := 0 to 54 do
    begin
        enemies[i].isActive := false;
    end;
    enemyCount := 0;
    state := 0;
    gametime := 0;
end;

//save-related procedures
procedure readHighScore();
begin
    assign(t, 'invaders_highscore.txt');
    reset(t);

    temp := 'x';

    while not eof(t) and (temp <> '') do
    begin
        readln(t, temp);
        scorename := copy(temp, 1, pos(';', temp) - 1);
        k := copy(temp, pos(';', temp) + 1);
        Val(k, highscore, code); //string to integer
    end;
    close(t);
end;

procedure writeHighScore();
begin
    assign(t, 'invaders_highscore.txt');
    rewrite(t);
    str(score, k); //integer to string

    temp := scorename + ';' + k;
    writeln(t, temp);
    close(t);
end;

procedure loadSaveData(); ///i wanna die lmao
begin
    assign(t, 'invaders_save.txt');
    reset(t);

    temp := 'x';

    while not eof(t) and (temp <> '') do
    begin
        readln(t, temp);

        //header
        if temp = '[ENEMIES]' then
        begin
            loadmode := 1;
        end
        else if temp = '[PLAYERBULLET]' then
        begin
            loadmode := 2;
        end
        else if temp = '[ENEMYBULLET]' then
        begin
            loadmode := 3;
        end;

        //actual data
        if (loadmode = 0) and (temp <> '[PLAYER]') then
        begin
            for i := 1 to 5 do
            begin
                k := copy(temp, 1, pos(';', temp) - 1); //take a segment of the string
                l := copy(temp, pos(';', temp) + 1); //cut the string

                temp := l; //put it back

                if i = 1 then
                begin
                    Val(k, playerX, code);
                end
                else if i = 2 then
                begin
                    Val(k, playerY, code);
                end
                else if i = 3 then
                begin
                    Val(k, lives, code);
                end
                else if i = 4 then
                begin
                    Val(k, score, code);
                end
                else
                begin
                    Val(k, gametime, code);
                    Val(l, gamestate, code);
                end;
            end;
        end
        else if (loadmode = 1) and (temp <> '[ENEMIES]') then
        begin
            for i := 1 to 5 do
            begin
                k := copy(temp, 1, pos(';', temp) - 1);
                l := copy(temp, pos(';', temp) + 1);

                temp := l;

                if i = 1 then
                begin
                    Val(k, j, code); //put index to j
                end
                else if i = 2 then
                begin
                    Val(k, enemies[j].id, code);
                end
                else if i = 3 then
                begin
                    Val(k, enemies[j].health, code);
                end
                else if i = 4 then
                begin
                    Val(k, enemies[j].x, code);
                end
                else
                begin
                    Val(k, enemies[j].y, code);
                    Val(l, m, code); //i need more temp integers

                    enemies[j].isActive := (m = 1);
                end;
            end;
        end
        else if (loadmode = 2) and (temp <> '[PLAYERBULLETS]') then
        begin
            for i := 1 to 3 do
            begin
                k := copy(temp, 1, pos(';', temp) - 1);
                l := copy(temp, pos(';', temp) + 1);

                temp := l;

                if i = 1 then
                begin
                    Val(k, j, code); //put index to j
                end
                else if i = 2 then
                begin
                    Val(k, bullet[j].x, code);
                end
                else
                begin
                    Val(k, bullet[j].y, code);
                    Val(l, m, code); //i need more temp integers

                    bullet[j].isActive := (m = 1);
                end;
            end;
        end
        else if (loadmode = 3) and (temp <> '[ENEMYBULLETS]') then
        begin
            for i := 1 to 3 do
            begin
                k := copy(temp, 1, pos(';', temp) - 1);
                l := copy(temp, pos(';', temp) + 1);

                temp := l;

                if i = 1 then
                begin
                    Val(k, j, code); //put index to j
                end
                else if i = 2 then
                begin
                    Val(k, enemyBullet[j].x, code);
                end
                else
                begin
                    Val(k, enemyBullet[j].y, code);
                    Val(l, m, code); //i need more temp integers

                    enemyBullet[j].isActive := (m = 1);
                end;
            end;
        end;
    end;
    close(t);
end;

procedure writeSaveData(); ///aaaaaaaaa
begin
    assign(t, 'invaders_save.txt');
    rewrite(t);
    //PLAYER section
    writeln(t, '[PLAYER]');
    str(playerX, temp); //save player x
    str(playerY, k);    //save player y
    str(lives, l);      //save lives
    temp := temp + ';' + k + ';' + l;
    str(score, k);      //save current score
    str(gametime, l);   //save game time
    temp := temp + ';' + k + ';' + l;
    str(state, k);      //save global enemy state
    temp := temp + ';' + k;
    writeln(t, temp);
    //ENEMIES section
    writeln(t, '[ENEMIES]');
    for i := 0 to 54 do
    begin
        str(i, temp);               //save index
        str(enemies[i].id, k);      //save enemy id
        str(enemies[i].health, l);  //save enemy health
        temp := temp + ';' + k + ';' + l;
        str(enemies[i].x, k);       //save enemy's x pos
        str(enemies[i].y, l);       //save enemy's y pos
        temp := temp + ';' + k + ';' + l;

        if enemies[i].isActive then //save active status via a number
        begin
            temp := temp + ';1';
        end
        else
        begin
            temp := temp + ';0';
        end;
        writeln(t, temp);
    end;

    //PLAYERBULLET
    writeln(t, '[PLAYERBULLET]');
    for i := 0 to 1 do
    begin
        str(i, temp);               //save index
        str(bullet[i].x, k);        //save bullet's x pos
        str(bullet[i].y, l);        //save bullet's y pos
        temp := temp + ';' + k + ';' + l;

        if bullet[i].isActive then
        begin
            temp := temp + ';1';
        end
        else
        begin
            temp := temp + ';0';
        end;
        writeln(t, temp);
    end;

    //ENEMYBULLET
    writeln(t, '[ENEMYBULLET]');
    for i := 0 to 10 do
    begin
        str(i, temp);               //save index
        str(enemyBullet[i].x, k);        //save bullet's x pos
        str(enemyBullet[i].y, l);        //save bullet's y pos
        temp := temp + ';' + k + ';' + l;

        if enemyBullet[i].isActive then
        begin
            temp := temp + ';1';
        end
        else
        begin
            temp := temp + ';0';
        end;
        writeln(t, temp);
    end;

    close(t);
end;

begin
    cursoroff;
    randomize;
    readHighscore();

    resetGameVars;
    newEnemies;

    bullet[0].dy := -1; bullet[1].dy := -1;

    for i := 0 to 10 do
    begin
        enemyBullet[i].dy := 1;
    end;

    show_menuHighscore := false;
    gamestate := 4;

    repeat
    begin
        clrscr;

        if gamestate <> 4 then //actual game
        begin
            textcolor(7);
            write('LIVES: ', lives);

            gotoxy(16, 1);
            write('SCORE: ', score);

            if (highscore <> 0) then
            begin
                gotoxy(42, 1);
                write('HI-SCORE: ', scorename);
                gotoxy(52, 2); write(highscore);
            end;

            gotoxy(36, 1);
            write('@x ', enemyCount);

            if (countdown = 0) and (not isPaused) then //game
            begin
                gametime := gametime + 1;

                //player
                textcolor(10); //light green
                if (gamestate = 0) or (gamestate = 1) then //normal play/win
                begin
                    gotoxy(playerX, playerY - 2);
                    write('*');
                    gotoxy(playerX - 1, playerY);
                    write('***');
                end
                else if (gamestate = 2) then //losing a life
                begin
                    playerFrame := playerFrame + 1;

                    if (playerFrame div 2 = 0) then
                    begin
                        gotoxy(playerX, playerY - 2);
                        write('*');
                        gotoxy(playerX - 1, playerY);
                        write('***');
                    end
                    else if (playerFrame div 2 = 1) then
                    begin
                        gotoxy(playerX, playerY - 1);
                        write('*');
                    end
                    else if (playerFrame div 2 = 2) then
                    begin
                        gotoxy(playerX, playerY - 2);
                        write('*');
                        gotoxy(playerX - 1, playerY - 1);
                        write('***');
                        gotoxy(playerX, playerY);
                        write('*');
                    end
                    else if (playerFrame div 2 = 3) then
                    begin
                        gotoxy(playerX - 1, playerY - 2);
                        write('* *');
                        gotoxy(playerX - 1, playerY);
                        write('* *');
                    end
                    else
                    begin
                        lives := lives - 1;
                        refresh_game();
                        playerFrame := 0;

                        if lives > 0 then
                        begin
                            gamestate := 0;
                        end
                        else
                        begin
                            gamestate := -1;
                        end;
                    end;
                end
                else if (gamestate = -1) then
                begin
                    gotoxy(36, 10);
                    write('GAME OVER');

                    if score > highscore then
                        newBest := true;

                    if newBest then
                    begin
                        highscore := score;
                        gotoxy(36, 13);
                        write('NEW BEST!');
                        gotoxy(36, 14);
                        write(highscore);
                        gotoxy(24, 16);
                        write('WRITE YOUR NAME: '); readln(scorename);
                        newBest := false;
                        writeHighScore(); //store them please, thank you
                        gamestate := 4;
                        score := 0; //flush score
                    end;
                end;

                //player bullet
                for i := 0 to 1 do
                begin
                    if bullet[i].isActive then
                    begin
                        //draw the bullets
                        gotoxy(bullet[i].x, bullet[i].y);
                        write('|');

                        //bullet behavior
                        if gamestate = 0 then
                        begin
                            bullet[i].y := bullet[i].y + bullet[i].dy;

                            if bullet[i].y <= 1 then
                                bullet[i].isActive := false;
                        end;
                    end;
                end;

                //enemy bullet
                for i := 0 to 11 do
                begin
                    //draw the bullets
                    if enemyBullet[i].isActive then
                    begin
                        gotoxy(enemyBullet[i].x, enemyBullet[i].y);
                        textcolor(15); write('|');

                        //bullet behavior
                        if gamestate = 0 then
                        begin
                            enemyBullet[i].y := enemyBullet[i].y + enemyBullet[i].dy;

                            if enemyBullet[i].y >= 25 then
                                enemyBullet[i].isActive := false;

                            if ((enemyBullet[i].x >= playerX - 1) and (enemyBullet[i].x <= playerX + 1)) and (enemyBullet[i].y >= playerY) then
                            begin
                                enemyBullet[i].isActive := false;
                                gamestate := 2;
                            end;
                        end;
                    end;
                end;

                //generating enemy bullets
                if (gametime mod shootinterval = 0) and (gamestate = 0) then
                begin
                    getRandomIndex(); //get a random alive enemy
                    rngRoll := random(99); //random 0-99 roll

                    if rngRoll >= 39 then //if high enough, shoot
                    begin
                        spawn_enemyBullet(enemies[randomIdx].x, enemies[randomIdx].y);
                    end;
                end;

                //enemies
                for i := 0 to 54 do
                begin
                    if enemies[i].isActive then
                    begin
                        //draw the enemies
                        textcolor(enemies[i].color);
                        if enemies[i].id = 1 then //@ enemy - 1 hit
                        begin
                            gotoxy(enemies[i].x, enemies[i].y);
                            write('@');
                        end
                        else if enemies[i].id = 2 then //& enemy - 2 hits
                        begin
                            gotoxy(enemies[i].x, enemies[i].y);
                            write('&');
                        end
                        else if enemies[i].id = 3 then //diamond enemy - 5 hits
                        begin
                            gotoxy(enemies[i].x, enemies[i].y - 1);
                            write('#');
                            gotoxy(enemies[i].x - 1, enemies[i].y);
                            write('###');
                            gotoxy(enemies[i].x, enemies[i].y + 1);
                            write('#');
                        end;

                        //enemy behaviors
                        //move
                        if gamestate = 0 then
                        begin
                            if (gametime mod moveinterval = 0) then
                            begin
                                enemies[i].x := enemies[i].x + enemies[i].dx;
                                enemies[i].y := enemies[i].y + enemies[i].dy;
                            end;

                            //assign dx and dy + change state globally if x is reached
                            if state = 0 then
                            begin
                                enemies[i].dx := 1;
                                enemies[i].dy := 0;

                                if (i >= 44) then //top-most row enemies
                                begin
                                    oldY := enemies[i].y;
                                end;

                                if enemies[i].x >= 78 then
                                begin
                                    state := 1;
                                end;
                            end
                            else if (state = 1) or (state = 3) then
                            begin
                                enemies[i].dx := 0;
                                enemies[i].dy := 1;

                                if (enemies[i].y = oldY + enemies[i].dy) then
                                begin
                                    if state = 3 then
                                    begin
                                        state := 0;
                                    end
                                    else
                                    begin
                                        state := 2;
                                    end;
                                end;
                            end
                            else //state = 2
                            begin
                                enemies[i].dx := -1;
                                enemies[i].dy := 0;

                                if (i >= 44) then //top-most row enemies
                                begin
                                    oldY := enemies[i].y;
                                end;

                                if enemies[i].x <= 4 then
                                begin
                                    state := 3;
                                end;
                            end;

                            //enemy/player bullet collision
                            for j := 0 to 1 do
                            begin
                                if (bullet[j].x = enemies[i].x) and (bullet[j].y = enemies[i].y) and (enemies[i].isActive and bullet[j].isActive) then
                                begin
                                    enemies[i].health := enemies[i].health - 1;
                                    bullet[j].isActive := false;

                                    if enemies[i].health = 0 then
                                    begin
                                        if enemies[i].id = 1 then //@
                                        begin
                                            score := score + 5;
                                        end
                                        else if enemies[i].id = 2 then //&
                                        begin
                                            score := score + 10;
                                        end
                                        else if enemies[i].id = 3 then //diamond
                                        begin
                                            score := score + 15;
                                        end;

                                        enemies[i].isActive := false;
                                        enemyCount := enemyCount - 1;
                                    end;
                                end;
                            end;
                        end;

                        //enemy colors: the more weakened, closer to white
                        if enemies[i].health = 1 then
                        begin
                            enemies[i].color := white;
                        end
                        else if enemies[i].health = 2 then
                        begin
                            enemies[i].color := yellow;
                        end
                        else if enemies[i].health = 3 then
                        begin
                            enemies[i].color := lightred;
                        end
                        else if enemies[i].health >= 4 then
                        begin
                            enemies[i].color := red;
                        end
                    end;
                end;

                //enemy movement interval
                if enemyCount > 44 then
                begin
                    moveinterval := 12;
                    shootinterval := 10;
                end
                else if enemyCount > 33 then
                begin
                    moveinterval := 10;
                    shootinterval := 9;
                end
                else if enemyCount > 22 then
                begin
                    moveinterval := 8;
                    shootinterval := 8;
                end
                else if enemyCount > 11 then
                begin
                    moveinterval := 6;
                    shootinterval := 7;
                end
                else if enemyCount > 0 then
                begin
                    moveinterval := (enemyCount div 4) + 2;
                    shootinterval := 6;
                end;

                delay(50);
            end
            else if (countdown <> 0) and (not isPaused) then //countdown
            begin
                countdown := countdown - 1;
                if countdown > 0 then
                begin
                    gotoxy(40, 13);
                    write(countdown);
                end
                else
                begin
                    gotoxy(39, 13);
                    write('GO!');
                end;

                delay(500);
            end
            else if isPaused then
            begin
                gotoxy(29, 10);
                write('======================');
                gotoxy(29, 11);
                write('|       PAUSED       |');
                gotoxy(29, 12);
                write('|   Continue         |');
                gotoxy(29, 13);
                write('|   Save & Continue  |');
                gotoxy(29, 14);
                write('|   Save & Exit      |');
                gotoxy(29, 15);
                write('|   Exit             |');
                gotoxy(29, 16);
                write('======================');

                textcolor(10); gotoxy(31, 12 + sel);
                write('>');

                delay(50);
            end;

            if keypressed and (countdown = 0) then
            begin
                ch := readkey;

                //move
                if gamestate = 0 then
                begin
                    if (not isPaused) then
                    begin
                        if (ch = #65) or (ch = #97) or (ch = #75) then
                        begin
                        if not (playerX <= 2) then
                            playerX := playerX - 1;
                        end
                        else if (ch = #68) or (ch = #100) or (ch = #77) then
                        begin
                            if not (playerX >= 79) then
                                playerX := playerX + 1;
                        end;

                        //shoot - press z
                        if (ch = #90) or (ch = #122) then
                        begin
                            spawn_playerBullet();
                        end;
                    end
                    else
                    begin
                        if (ch = #72) then //move arrows during pause
                        begin
                            sel := sel - 1;

                            if sel < 0 then
                                sel := 3;
                        end
                        else if (ch = #80) then
                        begin
                            sel := sel + 1;

                            if sel > 3 then
                                sel := 0;
                        end;

                        if (ch = #90) or (ch = #122) then //z key
                        begin
                            if sel = 1 then //save & continue
                            begin
                                writeSaveData();
                                delay(10);
                            end
                            else if sel = 2 then //save & exit
                            begin
                                writeSaveData();
                                delay(10);
                                gamestate := 4;
                                score := 0;
                                refresh_game();
                                resetGameVars();
                                ch := #65;
                            end
                            else if sel = 3 then //exit
                            begin
                                gamestate := 4;
                                score := 0;
                                refresh_game();
                                resetGameVars();
                                ch := #65;
                            end;

                            isPaused := false;
                        end;
                    end;
                end;

                if not newBest then
                begin
                    if (ch = #112) then //pause - press p (only lowercase)
                    begin
                        isPaused := not isPaused;
                    end;

                    if (ch = #27) then //esc
                    begin
                        gamestate := 4;
                        score := 0;
                        refresh_game();
                        resetGameVars();
                        ch := #65; //random character
                    end;
                end;
            end;

            textcolor(7);
        end
        else //menu
        begin
            //menu
            textcolor(white);
            gotoxy(32, 10); write('================');
            gotoxy(32, 11); write('|   NEW GAME   |');
            gotoxy(32, 12); write('|   LOAD GAME  |');
            gotoxy(32, 13); write('|   HIGH SCORE |');
            gotoxy(32, 14); write('|   EXIT       |');
            gotoxy(32, 15); write('================');

            //cursor
            textcolor(10);
            gotoxy(34, 11 + sel); write('>');

            //title
            gotoxy(29, 2); write('=== SPACE INVADERS ===');
            gotoxy(38, 4); write('&    #   @');
            gotoxy(24, 5); write('*'); gotoxy(42, 5); write('###        #  ');
            gotoxy(24, 6); write('* * -  -    @      #     &  ### ');
            gotoxy(24, 7); write('*'); gotoxy(40, 7); write('@'); gotoxy(53, 7); write('#');

            //high score
            if show_menuHighscore then
            begin
                gotoxy(24, 22);
                write('HIGH SCORE: ', scorename);
                gotoxy(36, 23);
                write(highscore);
            end;

            if keypressed then
            begin
                ch := readkey;

                if (ch = #72) then //up arrow
                begin
                    sel := sel - 1;

                    if sel < 0 then
                        sel := 3;
                end
                else if (ch = #80) then //down arrow
                begin
                    sel := sel + 1;
                    if sel > 3 then
                        sel := 0;
                end;

                if (ch = #90) or (ch = #122) then //z key
                begin
                    if sel = 0 then //new game
                    begin
                        resetGameVars();
    			newEnemies();
                        gamestate := 0;
                    end
                    else if sel = 1 then
                    begin
                        loadSaveData();
                        gamestate := 0;
                    end
                    else if sel = 2 then
                    begin
                        show_menuHighscore := not show_menuHighscore;
                    end
                    else //sel = 3
                    begin
                        exit;
                    end;
                end;
            end;
            delay(60);
        end;
    end;
    until (ch = #27) and (gamestate = 4);
end.
