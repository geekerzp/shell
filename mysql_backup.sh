##################################################################
#                        数据库自动备份脚本                      #
#                          作者：geekerzp                        #
#                              v 1.24                            #
#                                                                #
# 每天00:00自动备份数据库，每天最多备份一次，最多保留30天的备份  #
# 备份时删除旧二进制日志，新建二进制日志                         #
##################################################################
#!/bin/bash 

# Setting
# 设置数据库名，数据库登陆名，密码，备份路径，日志路径，数据库文件位置以及备份方式
# 备份方式可以是mysqldump，mysqldotcopy，或者直接使用tar
# 默认情况下，用root(空)登陆mysql数据库，备份至/var/mysql_dump/dbxxxx.tgz

DBName=test   # 数据库名称
DBUser=root                         # 用户名                        
DBPassword=913427                   # 密码
BackupPath=/var/mysql_dump/         # 备份路径
LogFile=/var/mysql_dump/db.log      # 日志文件路径
DBPath=/var/lib/mysql/              # mysql数据库文件路径

# BackupMethod
# 备份方式
# 1) mysqldump
BackupMethod=mysqldump        # 通过测试
# 2) mysqlhotcopy
#BackupMethod=mysqlhotcopy      # 通过测试
# 3) tar
#BackupMethod=tar 
# SettingEnd

NewFile="$BackupPath"db$(date "+%Y%m%d").tgz                    # 新备份文件
DumpFile=db$(date "+%Y%m%d")                                    # 临时备份文件
OldFile="$BackupPath"db$(date -d "30 days ago" "+%Y%m%d").tgz   # 过期备份文件（最多保留30天）

# 创建日志文件
if [ ! -d /var/mysql_dump/ ]; then 
  mkdir /var/mysql_dump/
fi 
if [ ! -f $LogFile ]; then
  touch $LogFile
fi

echo " " >> $LogFile  # 输出一个换行符，得到一个空白行
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $LogFile
echo $(date "+%Y-%m-%d %H:%M:%S") >> $LogFile
echo "----------------------------------------------------------------------------------------------------------" >> $LogFile

# DeleteOldFile
# 删除旧的备份，最多保留30天

if [ -f $OldFile ]; then
  rm -f $OldFile >> $LogFile 2>&1
  echo "[$OldFile]Delete OldFile Success!" >> $LogFile
else 
  echo "[$OldFile]No OldBackupFile!" >> $LogFile
fi

# CreateNewDump 

if [ -f $NewFile ]; then 
  echo "[$NewFile]The BackupFile Exists, Can't Backup!" >> $LogFile
else
  case $BackupMethod in 
    # 使用mysqldump进行备份，
    # --lock-tables在备份时进行表的锁定。
    mysqldump)
      echo "----------------------------------------------------------------------------------------------------" >> $LogFile
      echo "START BACKUP: $(date "+%Y-%m-%d %H:%M:%S")" >> $LogFile
      echo "----------------------------------------------------------------------------------------------------" >> $LogFile
      echo "WAITING......" >> $LogFile
      if [ -z $DBPassword ]; then
        mysqldump -u $DBUser --single-transaction --flush-logs --delete-master-logs $DBName 1> $BackupPath$DumpFile 2>> $LogFile
      else 
        mysqldump -u $DBUser -p$DBPassword --single-transaction --flush-logs --delete-master-logs $DBName 1> $BackupPath$DumpFile 2>> $LogFile
      fi
      echo "----------------------------------------------------------------------------------------------------" >> $LogFile
      echo "FINISHED BACKUP: $(date "+%Y-%m-%d %H:%M:%S")" >> $LogFile
      echo "----------------------------------------------------------------------------------------------------" >> $LogFile
      cd $BackupPath
      tar -czf $NewFile $DumpFile >> $LogFile 2>&1
      echo "[$NewFile]Backup Successfully!" >> $LogFile
      rm -rf $DumpFile 
    ;;
    # 使用hotcopy进行备份
    mysqlhotcopy)
      cd $BackupPath
      rm -rf $DumpFile
      mkdir $DumpFile
      if [ -z $DBPassword ]; then
        mysqlhotcopy -u $DBUser $DBName ./$DumpFile >> $LogFile 2>&1
      else 
        mysqlhotcopy -u $DBUser -p $DBPassword $DBName ./$DumpFile >> $LogFile 2>&1
      fi
      tar -czvf $NewFile $DumpFile >> $LogFile 2>&1 
      echo "[$NewFile]Backup Successfully!" >> $LogFile
      rm -rf $DumpFile
    ;;
    # 使用tar直接进行压缩
    *)
      /etc/init.d/mysql stop > /dev/null 2>&1
      tar -czvf $NewFile $DBPath$DBName >> $LogFile 2>&1
      /etc/init.d/mysql start > /dev/null 2>&1
    ;;
  esac
fi

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $LogFile







