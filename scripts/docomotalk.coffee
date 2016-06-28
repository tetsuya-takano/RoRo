# Description:
#   DOCOMO�̎G�kAPI�𗘗p�����G�k
#
# Author:
#   FromAtom

getTimeDiffAsMinutes = (old_msec) ->
  now = new Date()
  old = new Date(old_msec)
  diff_msec = now.getTime() - old.getTime()
  diff_minutes = parseInt( diff_msec / (60*1000), 10 )
  return diff_minutes

module.exports = (robot) ->
  robot.respond /(\S+)/i, (msg) ->
    DOCOMO_API_KEY = process.env.DOCOMO_API_KEY
    message = msg.match[1]
    return unless DOCOMO_API_KEY && message

    ## ContextID��ǂݍ���
    KEY_DOCOMO_CONTEXT = 'docomo-talk-context'
    context = robot.brain.get KEY_DOCOMO_CONTEXT || ''

    ## �O���b���Ă���̌o�ߎ��Ԓ��ׂ�
    KEY_DOCOMO_CONTEXT_TTL = 'docomo-talk-context-ttl'
    TTL_MINUTES = 20
    old_msec = robot.brain.get KEY_DOCOMO_CONTEXT_TTL
    diff_minutes = getTimeDiffAsMinutes old_msec

    ## �O���b���Ă����莞�Ԍo���Ă�����R���e�L�X�g��j��
    if diff_minutes > TTL_MINUTES
      context = ''

    url = 'https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue?APIKEY=' + DOCOMO_API_KEY
    user_name = msg.message.user.name

    request = require('request');
    request.post
      url: url
      json:
        utt: message
        nickname: user_name if user_name
        context: context if context
      , (err, response, body) ->
      		if err
      			console.log err
      			return
        ## ContextID�̕ۑ�
        robot.brain.set KEY_DOCOMO_CONTEXT, body.context

        ## ��b�������Ԃ̕ۑ�
        now_msec = new Date().getTime()
        robot.brain.set KEY_DOCOMO_CONTEXT_TTL, now_msec

        msg.send body.utt