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
	if params[:code] == secret_code
		if params[:first_name] == '' or params[:number] == ''
			'Please sign up with your first name and number.'
		else
			session[:first_name] = params[:first_name]
			session[:number] = params[:number]
			greetings.sample + ' ' + params[:first_name] + '. You will receive a confirmation message from me in a few minutes.'
		end
	end
end
 
#modify about page 
get '/about' do
	session["visits"] ||= 0
	session["visits"] = session["visits"] + 1 
	time = Time.now
	if session[:first_name].nil?
		'Is picking the food choice just another unsolved problem in your day? "Eatappy" is the food guide for you! Simply play a fun game by answering a few questions and I will tell you what kind of food you should get today. Eating is happy. Enjoy it! <br />Total visits on our website: ' + session["visits"].to_s
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
	404
end

#modify test/conversation page
get '/test/conversation' do
	body = params[:body]
	from = params[:from]
	if body.nil? or from.nil?
		puts 'Input for body and from are missing. Please give an input for body and from in the URL such as follows <br />localhost:4567/test/conversation?Body=Hi&From=1234567789'
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
	hi_vocabs = ["hi", "hello", "hey"]
	what_vocabs = ["what", "help", "feature", "function", "guide", "do"]
	who_vocabs = ["who", "you"]
	where_vocabs = ["where", "location", "city"]
	when_vocabs = ["when", "created", "born", "made"]
	why_vocabs = ["why", "purpose", "for", "meaning"]

	if body == 'hi' or has_vocab_in_sentence body, hi_vocabs
		'Hi I am "Eatappy". I am the food guide for you!'
	elsif body == 'who' or has_vocab_in_sentence body, who_vocabs
		'I am a MeBot. Want to know more about me? Try putting "fact" as an input for body!'
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