# app.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'twilio-ruby'

configure :development do
  require 'dotenv'
  Dotenv.load
end

enable :sessions

#glocal variables
greetings = ["Hi there,", "Hello,", "Hi,", "How are you?", "How's it going?"]
greetings_mn = ["Good morning", "Morning!"]
greetings_an = ["Good afternoon"]
greetings_en = ["Good evening"]
secret_code = "melanieiscool"

#modify signup page
get '/signup' do
	if params[:code] == secret_code
		erb :signup
	else
		404
	end
end

post '/signup' do
	#code to check parameters
	client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
	if params[:code] == secret_code
		if params[:first_name] == '' or params[:number] == ''
			'Please sign up with your first name and number.'
		else
			session[:first_name] = params[:first_name]
			session[:number] = params[:number]
			# this will send a message from any end point
			client.api.account.messages.create(
				from: ENV["TWILIO_FROM"],
				to: params[:number],
				body: 'Hi ' + session[:first_name] + ', you are all set!'
				)
			greetings.sample + ' ' + session[:first_name] + '. You will receive a confirmation message from me in a few minutes.'
		end
	end
end
 
#modify about page 
get '/about' do
	session["visits"] ||= 0
	session["visits"] = session["visits"] + 1 
	time = Time.now
	if session[:first_name].nil?
		'Is picking food an unsolved problem in your day? "Eatappy" is the food guide for you! Simply play a fun game by answering a few questions and I will tell you what kind of food you should get today. Eating is happy. Enjoy it! <br />Total visits on our website: ' + session["visits"].to_s
    else 
    	if session["visits"] > 10 #make a user a VIP after they visit the website more than 10 times
    		session[:first_name] + ', You are a VIP now!' + '<br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
    	else #show different greetings based on the time during a day
			if time.hour >= 5 and time.hour <= 14
				greetings_mn.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			elsif time.hour > 14 and time.hour <= 18
				greetings_an.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			else
				greetings_en.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			end
		end
	end
end

#modify incoming/sms page
get '/incoming/sms' do
	session["counter"] ||= 1
	body = params[:body] || ""
	#session[:first_name] = params[:first_name]

	if session["counter"] == 1
		message = "Hey, it's great to hear your first message! I am Eatappy. If picking food is an unsolved problem for your daily life, I am here to help you! 😋 Would you like to pick your food today? Reply yes or yeah to get started. "
		media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif" 
    else
    	message = determine_response body
    end
	
	# Build a twilio response object 
	twiml = Twilio::TwiML::MessagingResponse.new do |r|
		r.message do |m|

		# add the text of the response
	    	m.body ( message + "You said: " + body + "\n It's message number " + session["counter"].to_s )
				
			# add media if it is defined
	    	unless media.nil?
	    		m.media( media )
	    	end
	    end
    end

    # increment the session counter
    session["counter"] += 1

    # send a response to twilio 
    content_type 'text/xml'
    twiml.to_s
end

#modify test/conversation page
get '/test/conversation' do
	body = params[:body]
	from = params[:from]
	if body.nil? or from.nil?
		puts 'Input for body and from are missing. Please give an input for body and from in the URL such as follows <br />localhost:4567/test/conversation?body=Hi&From=1234567789'
		return
	else
		determine_response body
	end
end

#error 404
error 404 do
	"Access Forbidden"
end

#redirect
get '/' do 
	redirect '/about'
end

#methods

def determine_response body
	body = body.downcase.strip
	hi_vocabs = ["hi", "hello", "hey", "Hi", "Hello", "Hey"]
	what_vocabs = ["what", "help", "feature", "function", "guide", "What", "Help", "Feature", "Function", "Guide"]
	who_vocabs = ["who", "Who"]
	where_vocabs = ["where", "location", "city", "Where", "Location", "City"]
	when_vocabs = ["when", "created", "born", "made", "When", "Created", "Born", "Made"]
	why_vocabs = ["why", "purpose", "for", "meaning", "Why", "Purpose", "For", "Meaning"]
	yes_vocabs = ['Yes', 'Yeah', 'Yup', 'Sure', 'Sounds good', 'Ok', "yes", "yeah", "yup", "sure", "sounds good", "ok"]

	if body == 'hi' or has_vocab_in_sentence body, hi_vocabs
		'Hi, I am "Eatappy". I am the food guide for you!'
	elsif body == 'who' or has_vocab_in_sentence body, who_vocabs
		'I am a MeBot of Melanie Zeng. Want to know more about me? Try putting "fact" as an input for body!'
	elsif body == 'what' or has_vocab_in_sentence body, what_vocabs
		'Simply play a fun game with me by answering a few questions and I will help you to pick your food today!'
	elsif body == 'where' or has_vocab_in_sentence body, where_vocabs
		'I live in Pittsburgh!'
	elsif body == 'when' or has_vocab_in_sentence body, when_vocabs
		'I was created in Fall 2018!'
	elsif body == 'why' or has_vocab_in_sentence body, why_vocabs
		'I was made by Melanie Zeng for her Programming for Online Prototypes Class!'
	elsif body == 'joke'
		file = File.open("jokes.txt", "r")
		array_of_lines = IO.readlines("jokes.txt")
		return array_of_lines.sample + '<br /><br />Tell me if you like the joke by putting "jokewasgood" as an input for body. If not, put "jokewasbad" and I will try harder!'
	elsif body == 'jokewasgood'
		'Thank you for the complement. I am glad that you like it!'
	elsif body == 'jokewasbad'
		'Sorry, I am not good at jokes. But I will try harder :)'
	elsif body == 'fact'
		file = File.open("facts.txt", "r")
		array_of_facts = IO.readlines("facts.txt")
		return array_of_facts.sample
	elsif has_vocab_in_sentence body, yes_vocabs
		'Send me a selfie and let me see how you look now!'
	else
		"Oops! I didn't get that. Please put one of the follows as input for body: hi, who, what, where, when, why, joke, help and fact."
	end
end

#trigger conversation with sentence
def has_vocab_in_sentence words, vocabs
	vocabs.each do |vocab|
		if words.include? vocab
			return true
		end
	end
	return false
end
