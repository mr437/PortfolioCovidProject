--creating tables covid_vaccinations and covid_deaths
CREATE TABLE IF NOT EXISTS public.covid_vaccinations
(
	iso_code varchar,
	continent varchar,
	location varchar,
	date date,
	new_tests int,
	total_tests numeric,
	total_tests_per_thousand numeric,
	new_tests_per_thousand numeric,
	new_tests_smoothed numeric,
	new_tests_smoothed_per_thousand numeric,
	positive_rate numeric,
	tests_per_case numeric,
	tests_units varchar,
	total_vaccinations numeric,
	people_vaccinated numeric,
	people_fully_vaccinated numeric, 
	total_boosters numeric,
	new_vaccinations numeric,
	new_vaccinations_smoothed numeric,
	total_vaccinations_per_hundred numeric,
	people_vaccinated_per_hundred numeric,
	people_fully_vaccinated_per_hundred numeric,
	total_boosters_per_hundred numeric,
	new_vaccinations_smoothed_per_million numeric,
	new_people_vaccinated_smoothed numeric,
	new_people_vaccinated_smoothed_per_hundred numeric,
	stringency_index numeric,
	population_density numeric,
	median_age numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita numeric,
	extreme_poverty numeric,
	cardiovasc_death_rate numeric,
	diabetes_prevalence numeric,
	female_smokers numeric,
	male_smokers numeric,
	handwashing_facilities numeric,
	hospital_beds_per_thousand numeric,
	life_expectancy numeric,
	human_development_index numeric,
	excess_mortality_cumulative_absolute numeric,
	excess_mortality_cumulative numeric,
	excess_mortality numeric,
	excess_mortality_cumulative_per_million numeric
    );

ALTER TABLE public.covid_vaccinations
    OWNER to postgres;
	
CREATE TABLE IF NOT EXISTS public.covid_deaths
(
	iso_code varchar,
	continent varchar,
	location varchar,
	date date,
	population numeric,
	total_cases numeric,
	new_cases numeric,
	new_cases_smoothed numeric,
	total_deaths numeric,
	new_deaths numeric,
	new_deaths_smoothed numeric,
	total_cases_per_million numeric,
	new_cases_per_million numeric,
	new_cases_smoothed_per_million numeric,
	total_deaths_per_million numeric,
	new_deaths_per_million numeric,
	new_deaths_smoothed_per_million numeric,
	reproduction_rate numeric,
	icu_patients numeric,
	icu_patients_per_million numeric,
	hosp_patients numeric,
	hosp_patients_per_million numeric,
	weekly_icu_admissions numeric,
	weekly_icu_admissions_per_million numeric,
	weekly_hosp_admissions numeric,
	weekly_hosp_admissions_per_million numeric
    );

ALTER TABLE public.covid_deaths
    OWNER to postgres;

--importing data from csv files covid_vaccinations and covid_deaths

copy public.covid_deaths from 'covid_vaccinations.csv' with csv header;

copy public.covid_deaths from 'covid_deaths.csv' with csv header;

-- review the tables data 
select * from covid_deaths
order by 3,4;

select * from public.covid_vaccinations
order by 3,4;

-- Selecting data o be use for the project

SELECT location, date, total_cases, new_cases, total_deaths, population 
from covid_deaths
ORDER by 1,2;

--Total cases Vs total deaths
--Provavility to die if contract covid in specific conutry (example country ecuador)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covid_deaths
WHERE location like '%sta%'
ORDER by 1,2;

-- Comper the total cases vs population 
-- Indicates the porcentage of population infected whit covid
SELECT location, date, total_cases, population, (total_deaths/population)*100 as DeathPopulation
FROM covid_deaths
--WHERE location like '%sta%'
ORDER by 1,2;

-- Countries with highest infection rate cmpara from population
SELECT location, population, MAX(total_cases) as HighesInfectionCount, MAX((total_cases/population))*100 as PercentOfPopulationInfected
FROM covid_deaths
--WHERE location like '%sta%'
GROUP by location, population
ORDER by PercentOfPopulationInfected DESC;



-- Countries with highest death count of population
SELECT location, MAX(total_deaths)as TotalDeahtsCount
FROM covid_deaths
--WHERE location like '%sta%'
GROUP by location,
ORDER by TotalDeahtsCount DESC;


--Looking at the dta by continent
SELECT continent, MAX(total_deaths)as TotalDeahtsCount
FROM covid_deaths
--WHERE location like '%sta%'
WHERE continent is NOT NULL
GROUP by continent;
ORDER by TotalDeahtsCount DESC;

--Showing continents with highest death COUNT
SELECT continent, MAX(total_deaths)as TotalDeahtsCount
FROM covid_deaths
--WHERE location like '%sta%'
WHERE continent is NOT NULL
GROUP by continent;
ORDER by TotalDeahtsCount DESC;

--Global numbers covid cases and deaths by date 
SELECT date, SUM(new_cases) as totalcases, SUM(new_deaths) as totaldeahts, SUM(new_deaths)/SUM(new_cases)*100  as DeathPercentage
FROM covid_deaths
WHERE continent is NOT NULL
GROUP by date
--WHERE location like '%sta%'
ORDER by 1,2;

--Global numbers covid cases and deaths global numbers
SELECT  SUM(new_cases) as totalcases, SUM(new_deaths) as totaldeahts, SUM(new_deaths)/SUM(new_cases)*100  as DeathPercentage
FROM covid_deaths
WHERE continent is NOT NULL
--GROUP by date
--WHERE location like '%sta%'
ORDER by 1,2;

--Joint the tables covid_deaths and covid_vaccinations by location and date 
SELECT *
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date; 

--Looking at total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER by 1,2,3;	

--Looking at total Population vs Vaccinations
--Adding how many vaccinations per day every country has applyed (roling count)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rollingpeoplevaccinated	
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER by 2,3;	

-- Looking at how many people are vaccinated in every country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rollingpeoplevaccinated	
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER by 2,3;	

-- Creating a CTE (Common Table Expression) 
WITH cte_popvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated) 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rollingpeoplevaccinated	
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER by 2,3;
)
SELECT * ,(rollingpeoplevaccinated/population)*100
FROM cte_popvsvac;

--Temp TABLE
DROP TABLE if EXISTS PercentagePopulationVaccinated
CREATE TABLE PercentagePopulationVaccinated
(
continent CHARACTER VARYING,
location CHARACTER VARYING, 
date DATE, 
population NUMERIC, 
new_vaccinations NUMERIC, 
rollingpeoplevaccinated NUMERIC
)

INSERT INTO PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rollingpeoplevaccinated	
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER by 2,3;
)
SELECT * ,(rollingpeoplevaccinated/population)*100
FROM PercentagePopulationVaccinated;

--creating a visualization 
CREATE VIEW PercentagePopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rollingpeoplevaccinated	
FROM covid_deaths dea 
Join covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER by 2,3;
)












