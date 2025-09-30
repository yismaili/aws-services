import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'; 
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { PassportModule } from '@nestjs/passport';
import { HistoryEntity } from './typeorm/entities/History.entity';
import { Achievement } from './typeorm/entities/Achievement.entity';
import { Relation } from './typeorm/entities/Relation.entity';
import { Profile } from './typeorm/entities/Profile.entity';
import { User } from './typeorm/entities/User.entity';
import { UserModule } from './user/user.module';
import { ChatModule } from './chat/chat.module';
import { ChatRoom } from './typeorm/entities/chat-room.entity';
import { ChatRoomUser } from './typeorm/entities/chat-room-users.entity';
import { Message } from './typeorm/entities/message-entity';
import { Chat } from './typeorm/entities/chat-entity';
import { GameModule } from './game/game.module';
import { UserStatusModule } from './user-status/user-status.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }), 
    TypeOrmModule.forRoot({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT) || 5432,
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [User, Profile, Relation, Achievement, HistoryEntity, ChatRoom, ChatRoomUser, Message, Chat],
  autoLoadEntities: true,
  synchronize: true, // dev only
  ssl: {
    rejectUnauthorized: false
  },
}),
    AuthModule,
    PassportModule,
    UserModule,
    ChatModule,
    GameModule,
    UserStatusModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {

}