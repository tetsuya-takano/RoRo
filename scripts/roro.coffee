# Description:
#   RoRo.
#
# Notes:
#   RoRo

Cron = require('cron').CronJob

# 定数系はここで
channel 	= "#bot_room"
envelope	= room : channel

# 文言
AWAKE_MESSAGE 		= "おはよう！"
JOB_START_MESSAGE	= "お仕事！"

module.exports = (robot) ->
	# 定義

	# 関数

	# 送信
	sendCron = (str) =>
		robot.send envelope, str
	
	# 電車遅延通知
	checkTrainDelay = (obj, callback) ->
		url = 'https://rti-giken.jp/fhc/api/train_tetsudo/delay.json'
		request = obj.http(url).get()
		request (err, res, body) ->
			json = JSON.parse body 
						
			tables = {}
			for data in json
				if !tables[data.company]?
					tables[data.company] = []
				tables[data.company].push data.name
			
			fields = []
			for key,value of tables
				str = ""
				for d in value
					str += d+"\n"
				data = {
					title : key
					value : str
				}
				fields.push data
			content = 
			[{
				color	: "#819FF7"
				fallback: "電車遅延情報だよ!"
				pretext	: "今の遅延情報はこんな感じだよ!"
				fields	: fields
			}]
			callback(content)
	# 天気予報
	checkWeather = (obj, callback) ->
		url = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=130010' 
		request = obj.http(url).get()
		request (err, res, body) ->
			json 		= JSON.parse body 
			# 諸々整理
			dateTime	= new Date
			title		= json['title']
			description	= json['description']
			text		= description['text']
			weather		= json['forecasts'][0]
			month		= dateTime.getMonth() + 1
			days		= dateTime.getDate()
			hour		= dateTime.getHours()
			telop		= weather['telop']
			imageUrl	= weather['image']['url']
			# テキスト作成
			data =	[{
					fallback	: "天気予報だよ！"
					color		: "#36a64f"
					pretext		: "#{month}月#{days}日 #{hour}時の予報だよ！"
					title		: title
					title_link	: json['link']
					fields		: [{
						title	: telop
					}]
					image_url	: imageUrl
				}]
			callback(data)
			
	# 占い
	checkFortune = (obj, callback) ->
		date = new Date
		year = date.getFullYear()
		month= date.getMonth() + 1
		days = date.getDate()
		nowTimeStr = ""+year+"/"+("0"+month).slice(-2)+"/"+("0"+days).slice(-2)
		url = "http://api.jugemkey.jp/api/horoscope/free/" + nowTimeStr
		request = obj.http(url).get()
		request (err, res, body) ->
			json = JSON.parse body 
			sign = '蟹座'
			todayData = json["horoscope"][nowTimeStr]
			for data in todayData
				if data['sign'] == sign
					tmp = data['sign']
					break

			createGrade = ( name, count) ->
				star = ""
				for i in [0..count]
					star += '★' 
				ret = {
					title : name
					value : star
					short : true
				}
				ret

			fields = []
			fields.push( createGrade( "恋愛運", data['love'] ))
			fields.push( createGrade( "金運　", data['money']))
			fields.push( createGrade( "仕事運", data['job']))
			fields.push( createGrade( "総合運", data['total']))
			
			content = 
			[{
				color	:	"FF99CC"
				fallback:	"占いの結果が出たよ！"
				pretext	:	"今日の運勢はこちら!\n"
				title	:	"#{sign} : 第#{data['rank']}位"
				text	:	data['content']
				fields	:	fields
			}]
			callback(content)
	# 初期化
	init = (robot) ->
		# 起動メッセージ
		sendCron AWAKE_MESSAGE
	# スケジュール処理
	remind = (obj) ->
		jobStartCron = new Cron('0 0 10 * * 1-5',() =>
			sendCron JOB_START_MESSAGE
		)
		trainDelayCron 	= new Cron('0 0 9,19 * * 1-5',() =>
			checkTrainDelay obj, (data) ->
				robot.emit 'slack.attachment',
				{
					content	: data
					channel	: channel
				}
		)
		weatherCron		= new Cron('0 0 6-22/4 * * *',() =>
			checkWeather obj, (data) ->
				robot.emit 'slack.attachment',
				{
					content	: data
					channel	: channel
				}
		)
		fotuneCron		= new Cron('0 30 8 * * *',() =>
			checkFortune obj, (data) ->
				(data) ->
				robot.emit 'slack.attachment',
				{
					content	: data
					channel	: channel
				}
		)
		cronList = [ jobStartCron, trainDelayCron, weatherCron, fotuneCron ]
		for cron in cronList
			cron.start()
	# 初期化
	init(robot)
	# 定期処理登録
	remind(robot)
	# メッセージ反応処理
	robot.hear /遅延(.*)/i, (msg) ->
		checkTrainDelay msg, (data) ->
			robot.emit 'slack.attachment',
			{
				message : msg.message
				content	: data
			}
	robot.hear /天気(.*)/i, (msg) ->
		checkWeather msg, (data) ->
			robot.emit 'slack.attachment',
			{
				message : msg.message
				content	: data
			}
	robot.hear /運勢(.*)/i, (msg) ->
		checkFortune msg, (data) ->
			robot.emit 'slack.attachment',
			{
				message : msg.message
				content	: data
			}
