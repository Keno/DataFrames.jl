require("DataFrames")
using DataFrames

##############################################################################
#
# Introduction to Basic Types and Constructors
#
##############################################################################

#
# Missingness is indicated using a new type: NAtype
#

NAtype
typeof(NAtype)
super(NAtype)
dump(NAtype)

#
# There is a single value that has the type NAtype: it can
# created using either NAtype() or the shorter alias NA.
#

NAtype()
NA
typeof(NA)
dump(NA)

#
# As we'll see later, NA poisons all other scalar objects and
# recycles during interactions with non-scalar objects to poison
# them entrywise
#
# For now, we'll just demonstrate a single example of that poisoning
# behavior
#

NA + 1

#
# NA's represent missingness for scalar data. To express Arrays
# with missingness, we've define a new set of DataArray objects,
# a new parametric composite type that wraps a standard Julia array
# and complements this Julia array with an additional bit vector
# specifying which entries of the primary vector are missing.
#
# These two core components are stored in a DataArray's data and isna
# fields respectively. To save space, the isna field is always a BitArray.
#

DataArray
typeof(DataArray)
typeof(DataArray{Int64})
super(DataArray)
super(super(DataArray))
dump(DataArray)
DataArray.names

#
# The fundamental constructor for a DataArray specifies the data
# values and the missingness metadata
#

dv = DataArray([1, 2, 3], falses(3))

#
# A simpler type of constructor assumes that no data is missing and
# only specifies the vector of non-missing values.
#

dv = DataArray([1, 2, 3])

#
# Yet another constructor, which is conveniently brief, converts
# a Julian Range1 object into a standard Julia Vector and wraps
# this in a DataArray.
#

dv = DataArray(1:3)

#
# To order to provide a very concise constructor, we've hacked in
# a very cute constructor for DataVector's using a trick involving
# their ref() method.
#

dv = DataVector[1, 2, NA, 4]

#
# Because the missingness of a DataVector is stored in metadata rather than
# using existing values like NaN's, it is easy to create DataVector's
# that store arbitrary Julia types like ComplexPair's and Bool's.
#

dv = DataArray([1 + 2im, 3 - 1im])
dv = DataArray([true, false])

#
# Sometimes you want to convert all of the values inside a DataVector to
# a new type while preserving missingness. Where Julia has specialized
# conversion functions, DataArray's mimic them. Use the data* prefix to find
# them in the REPL
#

dv = DataArray([1.1, 2.1])

databool(dv)
dataint(dv)
datafloat(dv)

#
# Julia also provides convenience functions for generating initialized
# vectors with standard values. 
#

datazeros(5)
datazeros(Int64, 5)
dataones(5)
dataones(Int64, 5)
datafalses(5)
datatrues(5)

#
# If you know the type of the DataArray you want to create, but not the values
# you can create DataArray's of length N that are NA everywhere
#

dv = DataArray(Int64, 5)
dv = DataArray(Float64, 5)
dv = DataArray(ComplexPair, 5)

#
# While DataArray's are a very powerful tool for dealing with missing data,
# they only bring us part of the way towards representing real-world data
# sets in Julia. The missing piece is a tabular data structure like those
# found in relational databases or spreadsheets.
#
# To represent these kinds of data sets, we provide the DataFrame type. The
# DataFrame type is a new composite type with two fields:
#
# * columns: A Julia Vector{Any}, each element of which is a single
#            column. The typical column is a DataVector.
#
# * colindex: An Index object that allows one to access entries in the
#             columns. An Index can be constructed from an array of
#             ByteStrings. The details of the Index type are described
#             later.
#
# The DataFrame protocol requires that a DataFrame df behave as follows:
#
# * df is a table with M rows and N columns.
#
# * Every column of df has its own type, which is why a DataFrame is not
#   a matrix of DataVector's.
#
# * All columns of df are guaranteed to be of length M.
#
# * All columns of df are guaranteed to be capable of storing NA if it
#   is ever inserted. (NB: There is ongoing debate about whether a column
#	should always be a DataVector or whether it should only be converted to
#   a DataVector if an NA is introduced by assignment operations.)
#

df_columns = {datazeros(5), datafalses(5)}
df_colindex = Index(["A", "B"])

df = DataFrame(df_columns, df_colindex)

#
# In practice, many other constructors are more convenient to use. The
# simplest is to provide only the columns, which will produce default
# names for all the columns.
#

df = DataFrame(df_columns)

#
# One often would like to construct DataFrame's from columns which may
# not yet be DataVector's. This is possible using the same type of
# constructor. All columns that are not yet DataVector's will be converted
# to DataVector's. (THIS LAST CLAIM IS NOT YET TRUE AND TOM DOES NOT WANT IT.)
#

df = DataFrame({ones(5), zeros(5)})

#
# Often one wishes to convert an existing matrix into a DataFrame.
# This is also possible.
#

df = DataFrame(ones(5, 3))

#
# Like DataVector's, it is possible to create empty DataFrame's in which
# all of the default values are NA.
#
# In the simplest version, we specify a type, the number of rows
# and the number of columns.
#

df = DataFrame(Int64, 10, 5)

#
# Alternatively, one can specify a Vector of types. This implicitly
# defines the number of columns, but one must still specify the number
# of rows.
#

df = DataFrame({Int64, Float64}, 4)

#
# When you know what the names of the columns will be, but not the values
# it is possible to specify them as well.
#
# SHOULD THIS BE DataFrame(types, nrow, names) INSTEAD?
#

DataFrame({Int64, Float64}, ["A", "B"], 10)

# DataFrame({Int64, Float64}, Index(["A", "B"]), 10) NEED TO MAKE THIS WORK

#
# A more uniquely Julian way of creating DataFrame's exploits Julia's ability to
# quote Expressions in order to produce behavior like R's delayed evaluation
# strategy.
#

df = DataFrame(quote
				A = rand(5)
				B = datatrues(5)
			   end)

##############################################################################
#
# Indexing and Assignment Elements
#
##############################################################################

#
# Because a DataVector is a 1-dimensional Array, indexing into it is trivial and
# behaves exactly like indexing into a standard Julia vector.
# 

dv = dataones(5)
dv[1]
dv[5]
dv[end]
dv[1:3]
dv[[true, true, false, false, false]]

dv[1] = 3
dv[5] = 5.3
dv[end] = 2.1
dv[1:3] = [3.2, 3.2, 3.1]
# dv[[true, true, false, false, false]] = dataones(2) # SHOULD WE MAKE THIS WORK?

#
# In contrast, a DataFrame is a random-access data structure that can be
# indexing into and assigned to in many different ways. We walk through
# them one-by-one below.
#

#
# Simple numeric indexing
#

df = DataFrame(Int64, 5, 3)
df[1, 3]
df[1]

#
# Range numeric indexing:
#

df = DataFrame(Int64, 5, 3)

df[1, :]
df[:, 3]
df[1:2, 3]
df[1, 1:3]
df[:, :]

#
# Column name indexing
#

df["x1"]
df[1, "x1"]
df[1:3, "x1"]

df[["x1", "x2"]]
df[1, ["x1", "x2"]]
df[1:3, ["x1", "x2"]]

##############################################################################
#
# Unary Operators for NA, DataVector's and DataFrame's
#
# +
# -
# !
#
# MISSING: The transpose unary operator
#
##############################################################################

+NA
-NA
!NA

+dataones(5)
-dataones(5)
!datafalses(5)

##############################################################################
#
# Binary Operators
#
# * Arithmetic Operators
#   +, .+, -, .-, *, .*, /, ./, ^, .^
#
# * Bit Operators
#   MISSING
#
# * Comparison Operators
#   ==, !=, <, <=, >, >=, .==, .!=, .<, .<=, .>, .>=
#
##############################################################################

#
# The standard arithmetic operators work on DataVector's when
# they interact with Number's, NA's or other DataVector's.
#

dv = dataones(5)
dv[1] = NA
df = DataFrame(quote
				 a = 1:5
			   end)

#
# NA's with NA's
#

NA + NA
NA .+ NA
# And so on for -, .- , *, .*, /, ./, ^, .^ 

#
# NA's with scalars and scalars with NA's
#

1 + NA
1 .+ NA
NA + 1
NA .+ 1
# And so on for -, .- , *, .*, /, ./, ^, .^ 

#
# NA's with DataVector's
#

dv + NA
dv .+ NA
NA + dv
NA .+ dv
# And so on for -, .- , *, .*, /, ./, ^, .^ 

#
# DataVector's with scalars
#

dv + 1
dv .+ 1
# And so on for -, .- , .*, ./, .^ 

#
# Scalars with DataVector's
#

1 + dv
1 .+ dv
# And so on for -, .- , *, .*, /, ./, ^, .^ 

# HOW MUCH SHOULD WE HAVE OPERATIONS W/ DATAFRAMES?

NA + df
df + NA
1 + df
df + 1
# dv + df # SHOULD THIS EXIST?
# df + dv # SHOULD THIS EXIST?
df + df
# And so on for -, .- , .*, ./, .^ 

#
# The standard bit operators work on DataVector's
#

# MISSING

#
# The standard comparison operators work on DataVector's
#

NA .< NA
NA .< "a"
NA .< 1
NA .== dv

dv .< NA
dv .< "a"
dv .< 1
dv .== dv

df .< NA
df .< "a"
df .< 1
# df .== dv # SHOULD THIS EXIST?
df .== df

##############################################################################
#
# Elementwise Functions
#
# abs, sign, acos, acosh, asin, asinh, atan, atan2, atanh, sin, sinh
# cos, cosh, tan, tanh, ceil, floor, round, trunc, signif, exp, log
# log10, log1p, log2, logb, sqrt
#
##############################################################################

#
# Standard functions that apply to scalar values of type Number
# return NA when applied to NA.
#

abs(NA)

#
# Standard functions are broadcast to the elements of DataVector's and
# DataFrame's for elementwise application.
#

dv = dataones(5)
df = DataFrame({dv})

abs(dv)
abs(df)

##############################################################################
#
# Pairwise Functions
#
# diff
#
##############################################################################

#
# Functions that operate on pairs of entries of a Vector work on DataVector's
# and insert NA where it would be produced by other operator rules
#

diff(dv)

##############################################################################
#
# Cumulative Functions
#
# cumprod, cumsum, cumsum_kbn
#
# MISSING: cummin, cummax
#
##############################################################################

#
# Functions that operate cumulatively on the entries of a Vector work on
# DataVector's and insert NA where it would be produced by other operator rules
#

cumprod(dv)
cumsum(dv)
cumsum_kbn(dv)

##############################################################################
#
# Aggregative Functions
#
# min, max, prod, sum, mean, median, std, var, fft, norm
#
##############################################################################

min(dv)

#
# To broadcast these to individual columns, use the col*s versions:
# colmins, colmaxs, colprods, colsums, colmeans, colmedians,
# colstds, colvars, colffts, colnorms
#

colmins(df)

##############################################################################
#
# Loading Standard Data Sets
#
##############################################################################

#
# The DataFrames package is easiest to explore if you also install the
# RDatasets package, which provides access to 570 classic data sets.
#

require("RDatasets")

iris = RDatasets.data("datasets", "iris")
dia = RDatasets.data("ggplot2", "diamonds")

##############################################################################
#
# Split-Apply-Combine
#
##############################################################################

#
# The basic mechanism for spliting data is the groupby() function,
# which will produce a GroupedDataFrame() object that is easiest to
# interact with by iterating over its entries
#

for df in groupby(iris, "Species")
	println("A DataFrame with $(nrow(df)) rows")
end

#
# The | (pipe) operator for GroupedDataFrame's allows you to run
# simple functions on the columns of the induced DataFrame's.
#
# You pass a simple function by producing a symbol with its name.
# 

groupby(iris, "Species") | :mean

#
# Another simple way to split-and-apply (without clear combining) is to
# use the map() function
#

map(df -> mean(df[1]), groupby(iris, "Species"))

##############################################################################
#
# Reshaping
#
##############################################################################

#
# If you are looking for the equivalent of the R "Reshape" packages melt()
# and cast() functions, you can use stack() and unstack()
#
# Note that these functions have exactly the oppposite syntax as melt()
# and cast()
#

stack(iris, ["Petal.Length", "Petal.Width"])
