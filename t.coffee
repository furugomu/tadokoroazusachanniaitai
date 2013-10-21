express = require 'express'
http = require 'http'
path = require 'path'
ntwitter = require 'ntwitter'
passport = require 'passport'

app = express()
app.set 'port', process.env.PORT || 5000
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.favicon()
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser(process.env['SESSION_SECRET'])
app.use express.session()
app.use passport.initialize()
app.use passport.session()
app.use app.router
app.use express.static(path.join(__dirname, 'public'))

app.use express.errorHandler() if app.get('env') == 'development'

# ー
app.get '/', (req, res) ->
  res.render 'index'

app.get '/done', (req, res) ->
  res.render 'done'

app.get '/auth/twitter/failure', (req, res) ->
  res.render 'auth-failure'

app.get '/failure', (req, res) ->
  res.render 'failure'

# passport
passport.serializeUser (user, done) ->
  done(null, user)

passport.deserializeUser (obj, done) ->
  done(null, obj)

TwitterStrategy = require('passport-twitter').Strategy
passport.use(new TwitterStrategy(
  consumerKey: process.env['TWITTER_CONSUMER_KEY']
  consumerSecret: process.env['TWITTER_CONSUMER_SECRET']
  callbackURL: 'http://192.168.6.142:5000/auth/twitter/callback'
, (token, tokenSecret, profile, done) ->
  user =
    token: token
    secret: tokenSecret
    profile: profile
  done(null, user)
))

app.get '/auth/twitter', passport.authenticate('twitter')
app.get '/auth/twitter/callback',
  passport.authenticate('twitter', failureRedirect: '/auth/twitter/failure'),
  (req, res) ->
    # oAuth できたらすぐにツイート
    twitter = new ntwitter
      consumer_key: process.env['TWITTER_CONSUMER_KEY']
      consumer_secret: process.env['TWITTER_CONSUMER_SECRET']
      access_token_key: req.user.token
      access_token_secret: req.user.secret
    twitter.updateStatus '田所あずさちゃんに会いたい', (err) ->
      if err
        console.log(err)
        res.redirect('/failure')
      else
        res.redirect('/done')

#
http.createServer(app).listen app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
