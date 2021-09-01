=begin

Taylor Nguyen

Partners: N/A

What it is: Genetic algorithm to find an ideal alphabet key for the monoalphabetic substitution cipher.

How it works: Uses chi squared in order to determine fittness based on frequency of letters in the enciphered text in comparison to the standard letter frequency of the English language. It establishes the best fit alphabets and then selects a lucky few from a randomly generated poulation and breeds them to ideally produce an alphabet with a lower chi squared score. It then mutates the children of the function to allow for variablility in the alphabets to prevent the program from stopping at a local minimum. When the best chi squared score of the population is <5, or when the generations occurs n number of times, the program selects the best score and translates the text. 

Challenges: I faced most of my challenges when it came to breeding the alphabets and general manipulation of the "alphabet pairs" (alphabets and scores). When it came to breeding, it wasn't possible to just take half of each function becuase it could result in alphabets with duplicate letters. Instead I used a "find and replace" type function that resolved duplicates. I also found that the theory  was difficult at times (learning how genetic algorithms and the cipher itself worked). Because no one really writes in standard English letter frequency, there's a change that my program could produce an alphabet that's close, but there's no guarantee because some of the letters are close in frequency.

P.S. I realized the reason it wasn't displaying anything during the presentation was because I took the section of code that prints the highest population out of the loop, so it would only display at the very end.

=end



# removes all non-alphabetic characters
def clean(text)
  cleanedText = text.upcase.gsub(/[^A-Z]/, '')
  return cleanedText
end

#returns number of instances of each letter 
def letterCount(text)
  freq = ('A'..'Z').to_a.zip([0]*26).to_h
  text.split('').each{|c| freq[c] += 1}
  return freq
end

#scores text based on chi squared 
def score(text)
  count = count(text)[0].values
  expectedCount = count(text)[1].values
  #actually gets chi squared score (math stuff)
  sum = 0 
  count.each_index{|i| sum += (count[i] - expectedCount[i])**2 / expectedCount[i]}
  return sum
end

def count(text)
  freqStan = [0.08167, 0.01492, 0.02782, 0.04253, 0.12702, 0.02228, 0.02015, 0.06094, 0.06966, 0.00153, 0.00772, 0.04025, 0.02406, 0.06749, 0.07507, 0.01929, 0.00095, 0.05987, 0.06327, 0.09056, 0.02758, 0.00978, 0.02360, 0.00150, 0.01974, 0.00074]
  #array of count of each letter in text
  count = letterCount(clean(text))
  #expected counts of each letter (array) in text
  expectedCount = freqStan.map{|i| (i * clean(text).split('').count)}
  expectedCount = ('A'..'Z').to_a.zip(expectedCount).to_h
  return count, expectedCount
end

#returns an alphabet
def alphabetGenerator(text)
  #getting frequency of text and expected frequency
  count = count(text)[0]
  expectedCount = count(text)[1]
  #sorts letters by value and converts to a hash
  count = count.sort_by{|k, v| v}.to_h
  expectedCount = expectedCount.sort_by{|k, v| v}.to_h
  #creates a hash where the letters correspond to letters with closest matching frequencies 
  legend = expectedCount.keys.zip(count.keys).sort_by{|k, v| k}.to_h
  #creates alphabet and scores
  alphabetPair = [legend.values.join, score(translator(legend.values, text))]
  #mutates alphabet for variability
  alphabet = mutateAlphabet(alphabetPair, 10, text)
  return alphabet
end

#generates a population of alphabets and their cooresponding scores
def populationGenerator(n, text)
  alphabets = []
  #generates n number of alphabets and adds them to alphabets, finds their scores and adds them to scores
  n.times do 
    new = alphabetGenerator(text)
    alphabets << new
  end
  return alphabets
end


#returns ciphertext translated with new alphabet
def translator(alphabet, text)
  #makes a hash legend to translator
  rosettaStone = ('A'..'Z').zip(alphabet).to_h
  #translates text using legend
  this = text.split('').map{|c| rosettaStone[c]}
  return this.join()
end

#survival of the fittest
def reaping(origPopulation, best, lucky)
  #make a new population sorted by score
  population = origPopulation.sort_by{|k, v| v}
  #takes the first alphabets, best
  survivors = population.shift(best)
  #takes lucky number of alphabets as the lucky few who survive
  survivors += population.sample(lucky)
  return survivors.sort_by{|k, v| v}
end

def createChildren(breeders, number, text)
	nextPopulation = []
  #creates two element arrays of parent pairs
  breeders = breeders.to_h.keys.each_slice(2).to_a
  #resolves any "single people" if number of breeders is odd
  breeders.select!{|e| e.count == 2}
  #for each pair of breeders, create a child and add them to the "new population"
	for i in 0..(breeders.count - 1)
		for j in 0..number
			nextPopulation << createChild(breeders[i][0], breeders[i][1], text)
    end
  end
	return nextPopulation
end

#breeds together two alphabets to create a baby alphabet
def createChild(parent1, parent2, text)
  child = []
  parent1 = parent1.split('')
  parent2 = parent2.split('')
  #for each index of alphabet (26)
	for i in (0..parent1.length - 1)
    #if child has the letter at i in parent1 and in parent2, add value 'nil' 
		if child.include?(parent2[i]) && child.include?(parent1[i])
      child << nil
    else 
      #if child includes the letter at i in parent2, add the letter at i in parent1
      if child.include?(parent2[i])
        child << parent1[i]
      #if child includes the letter at i in parent1, add the letter at i in parent2
      elsif child.include?(parent1[i])
        child << parent2[i]
      #if child doesn't include the letter at i of parent1 or parent2, get a random number to decide which alphabet to take from
      else 
        #if a random number is less than 50, addd the letter at i of parent1
        if (100 * rand < 50)
          child << parent1[i]
        #if a random number is greater than 50, addd the letter at i of parent2
        else
          child << parent2[i]
        end
      end
    end
  end
  #natural mutation
  #find the letters missing from the baby alphabet and shuffles
  left = ('A'..'Z').select{|l| child.join.include?(l) == false}
  #implements missing letters at nil indices in child
  offspring = child.map{|l| l == nil ? left.sample() : l }
	return offspring.join, score(translator(offspring, text))
end

def mutateAlphabet(alphabet, chance, text)
  #splits alphabet
  alphabet = alphabet[0].split('')
  #for each letter in the alphabet, it evaluates if that letter has a chance of mutation
  for i in 0..alphabet.count - 1  
    if rand() * 100 < chance
      #switches letter at index, i, with a different index that follows index, i
      j = rand(i..alphabet.count - 1)
      alphabet[i], alphabet[j] =  alphabet[j], alphabet[i]
    end
  end
  return alphabet.join, score(translator(alphabet, text))
end
	
def mutatePopulation(population, chance, text)
  #for each alphabet, mutate the alphabet
	for i in 0..population.count - 1
		population[i] = mutateAlphabet(population[i], chance,text)
  end
	return population
end

def bestFit(text, populationSize, numBest, numLucky, numChildren, chanceMutation, x)
  text = clean(text)
  #generates a population
  population = populationGenerator(populationSize, text).to_a
  firsts = []
  #runs through each step of the genetic algorithm
  x.times do 
    #reaps the population
    survivors = reaping(population, numBest, numLucky)
    #creates children
    children = createChildren(survivors, numChildren, text)
    #mutates children
    mutated = mutatePopulation(children, chanceMutation, text)
    #reaps the children and the survivors AKA next generation
    population = reaping(children + survivors, numBest, numLucky)
    print(population[0])
    #breaks if the chi squared score is less than 5
    if population[0][1] <= 0.06
      break 
    end
    #rinse and repeat otherwise
  end
  return translator(population[0][0].split(''), text)
end

#reads from txt file to ciphertext
#text.txt - QWERTYUIOPASDFGHJKLZXCVBNM
#warandpeace.txt - AZERTYUIOPQSDFGHJKLMWXCVBN

#=begin
ciphertext = ""

File.open("text.txt", 'r') do |file|
  ciphertext = file.to_a.to_s
end
#=end

#generates a string of letters in all of their corresponding frequencies
=begin
this = [0.08167, 0.01492, 0.02782, 0.04253, 0.12702, 0.02228, 0.02015, 0.06094, 0.06966, 0.00153, 0.00772, 0.04025, 0.02406, 0.06749, 0.07507, 0.01929, 0.00095, 0.05987, 0.06327, 0.09056, 0.02758, 0.00978, 0.02360, 0.00150, 0.01974, 0.00074]

that = ('A'..'Z').to_a.zip(this.map{|i| i * 10000}).to_h
s = ''
that.each{|k, v| s << k * v}
ciphertext = s
=end

#bestFit(text, population size, number of best fit, number of lucky survivors, number of children, chance of mutation,# of generations)
bestFit(ciphertext, 10, 5, 2, 4, 20, 1000)
