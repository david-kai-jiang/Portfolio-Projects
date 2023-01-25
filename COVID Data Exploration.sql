/* Skills used: Joins, CTE's, Temp Tables, Aggregate Functions */


SELECT *
FROM `rare-ridge-375312.covid_data.covid_deaths` 
WHERE continent IS NOT null
ORDER BY 3,4



--Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `rare-ridge-375312.covid_data.covid_deaths`
WHERE continent IS NOT null
ORDER BY 1, 2 



-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `rare-ridge-375312.covid_data.covid_deaths`
WHERE location LIKE '%States%' AND continent IS NOT null
ORDER BY 1, 2 



-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM `rare-ridge-375312.covid_data.covid_deaths`
--WHERE location LIKE '%States%'
ORDER BY 1, 2 


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS percent_population_infected
FROM `rare-ridge-375312.covid_data.covid_deaths`
--WHERE location LIKE '%States%'
GROUP BY location, population
ORDER BY percent_population_infected desc



-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS total_death_count
FROM `rare-ridge-375312.covid_data.covid_deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NOT null
GROUP BY location
ORDER BY total_death_count desc


-- Breaking things down by continent ---------------------------------------

-- Showing continents with the highest death count per population
SELECT continent, MAX(total_deaths) AS total_death_count
FROM `rare-ridge-375312.covid_data.covid_deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NOT null
GROUP BY continent
ORDER BY total_death_count desc


-- Global numbers

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM `rare-ridge-375312.covid_data.covid_deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NOT null
ORDER BY 1, 2 


-- Looking at Total Population vs Vaccinations
-- Shows percentage of population that has received at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations, 
FROM `rare-ridge-375312.covid_data.covid_deaths` AS dea
JOIN `rare-ridge-375312.covid_data.covid_vaccinations` AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT null 
ORDER BY 2, 3


-- Using CTE to perform calculation on "partition by" in previous query
WITH pop_vs_vac AS (

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations
FROM `rare-ridge-375312.covid_data.covid_deaths` AS dea
JOIN `rare-ridge-375312.covid_data.covid_vaccinations` AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT null
)

Select *, (cumulative_vaccinations/population)*100
FROM pop_vs_vac


-- Temp table

DROP TABLE IF EXISTS `rare-ridge-375312.covid_data`.percent_population_vaccinated
CREATE TABLE `rare-ridge-375312.covid_data`.percent_population_vaccinated (
continent STRING,
location STRING,
date DATETIME,
population INTEGER,
new_vaccinations INTEGER,
cumulative_vaccinations NUMERIC
)

INSERT INTO `rare-ridge-375312.covid_data`.percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations
FROM `rare-ridge-375312.covid_data.covid_deaths` AS dea
JOIN `rare-ridge-375312.covid_data.covid_vaccinations` AS vac
  ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.continent IS NOT null

Select *, (cumulative_vaccinations/population)*100
FROM `rare-ridge-375312.covid_data`.percent_population_vaccinated
--WHERE location = "Albania"
--ORDER BY new_vaccinations DESC
