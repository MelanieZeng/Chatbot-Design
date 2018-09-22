# app.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'twilio-ruby'
require 'rest-client'

configure :development do
  require 'dotenv'
  Dotenv.load
end

enable :sessions

#glocal variables
greetings = ["Hi there,", "Hello,", "Hi,", "How are you?", "How's it going?"]
greetings_mn = ["Good morning!", "Morning!"]
greetings_an = ["Good afternoon!"]
greetings_en = ["Good evening!", "Evening!"]
secret_code = "melanieiscool"

#List all ingredients of Foodpairing API
get '/food' do

	puts "hey"

	response = RestClient.get "https://api.foodpairing.com/ingredients/list-all-ingredients", headers: {
		:"X-Application-ID" => ENV['X-Application-ID'], 
		:"X-Application-Key" => ENV['X-Application-Key'], 
		:"X-API-Version" => 1, 
		Accept: "application/json"
	}
	puts response
end

get '/' do 
	session["visits"] ||= 0
	session["visits"] = session["visits"] + 1 
	time = Time.now
	if session[:first_name].nil?
		'What is the best food and drink for a summer night when you are sitting at the bench in your backyard and enjoying the wind gently blowing through your hair? Show me a selfie and I will customize the best food + drink combincation for you! Sign up to chat with me now! <br />Total visits on our website: ' + session["visits"].to_s
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

#modify incoming/sms page
get '/incoming/sms' do
	session["counter"] ||= 1
	time = Time.now

	body = params[:Body] || ""

	if session["counter"] == 1
		#greeting based on different time of a day
		if time.hour >= 5 and time.hour <= 12
    		message = greetings_mn.sample + " It's great to hear your first message! I am Eatappy. 😋 Would you like to pick your breakfast or lunch? Send me a seflie that best describes your mood now! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		elsif time.hour > 12 and time.hour <= 18
			message = greetings_an.sample + " It's great to hear your first message! I am Eatappy. 😋 Would you like to pick your lunch or hightea? Send me a seflie that best describes your mood now! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		else
			message = greetings_en.sample + " It's great to hear your first message! I am Eatappy. 😋 Would you like to pick your dinner? Send me a seflie that best describes your mood now! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		end
    else
    	message = determine_response body
    end
	
	#allow users to upload selfies - Should it be query or header??
	response = RestClient.post "https://api-us.faceplusplus.com/facepp/v3/detect", query: {
		"api_key" => ENV['api_key'],
		"api_secret" => ENV['api_secret'],
		"image_url" => "http://something.some/image.jpg" 
	}

	#skinstatus = response.skinstatus
	#emotion = response.emotion

	# Build a twilio response object 
	twiml = Twilio::TwiML::MessagingResponse.new do |r|
		r.message do |m|

		# add the text of the response
	    	m.body ( message )
				
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

#error 404
error 404 do
	"Access Forbidden"
end

#methods
def determine_response body
	body = body.downcase.strip
	hi_vocabs = ["hi", "hello", "hey"]
	what_vocabs = ["what", "help", "feature", "function", "guide"]
	who_vocabs = ["who"]
	where_vocabs = ["where", "location", "city"]
	when_vocabs = ["when", "created", "born", "made"]
	why_vocabs = ["why", "purpose", "for", "meaning"]
	joke_vocabs = ["joke", "jokes", "bored", "fun"]
	yes_vocabs = ["yes", "yeah", "yup", "sure", "sounds good", "ok", "I'd love to"]

	if has_vocab_in_sentence body, hi_vocabs
		'Hi, I am Eatappy. I am the food guide for you! Send me a selfie and I will customize your food and drink based on your mood. '
	elsif has_vocab_in_sentence body, who_vocabs
		'I am a MeBot of Melanie Zeng. Reply "fact" to know more about Melanie! '
	elsif has_vocab_in_sentence body, what_vocabs
		'Let me know how you feel by showing me a selfie and I will help you to pick your food and drink! '
	elsif has_vocab_in_sentence body, where_vocabs
		'I live in Pittsburgh! '
	elsif has_vocab_in_sentence body, when_vocabs
		'I was created in Fall 2018! '
	elsif has_vocab_in_sentence body, why_vocabs
		'I was made by Melanie Zeng for her Programming for Online Prototypes Class! '
	elsif has_vocab_in_sentence body, joke_vocabs
		file = File.open("jokes.txt", "r")
		array_of_lines = IO.readlines("jokes.txt")
		return array_of_lines.sample + "\n Reply 'Joke was good' if you like it or 'Joke was bad' if you don't. Don't be mean to me please!"
	elsif body.include? 'Joke was good'
		'Thank you for the complement. I am glad that you like it!'
	elsif body.include? 'Joke was bad'
		'Sorry, I am not good at jokes. But I will try harder :)'
	elsif body == 'fact'
		file = File.open("facts.txt", "r")
		array_of_facts = IO.readlines("facts.txt")
		return array_of_facts.sample
	else
		"Oops! I didn't get that. Reply 'hi', 'who', 'what' or 'why' if you want to learn more about me. "
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
