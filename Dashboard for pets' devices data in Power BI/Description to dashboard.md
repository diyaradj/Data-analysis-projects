In this project, I create an interactive report in Power BI that helps a company to make business decisions. This company produces smart devices for pets, it has already created a collar for dogs. This collar allows to track daily steps, activity minutes, and heartbeat for a dog. The device for dogs got positive reviews from owners of dogs. So the company created a similar collar for cats. In order to test the smart device for cats, the company distributed one thousand collars to owners of cats.   
The report that I created helps the company’s management team to make decision about viability of the smart device for cats. The report contains three pages: overview of the two smart devices, information about pets, and information about owners of pets. Users can navigate between pages of the report using buttons at the top right corner and filter the data using slicers on the pages.   
The first page is an overview of the two smart devices.  
  
<a href="report page 1.png"><img src="images/report page 1.png" style="min-width: 300px"></a>  
  
The first page contains two line charts for daily steps of dogs and cats. Daily steps of dogs increased significantly in the first year of use of the device, and daily steps increased steadily every year. While daily steps of cats were volatile, they didn't increase throughtout the year, and overall daily steps of cats are lower than daily steps of dogs.  
Next, the report contains column chart of the average rating of the two devices. On scale of 1 to 5, rating of the device for dogs is 4.7 and is quite high. While rating of the device for cats is 1.6 and is quite low, so owners of cats are not happy with the device for cats.  
Moreover, when asked whether they would recommend the device, 90% of dogs' device's users responded that they would recommend the device, while 90% of cats' device's users responded that they wouldn't recommend the device. Again, there is an evidence that owners of cats are not happy with the device for cats.  
The second page contains information about pets and has two modes: *information about dogs* and *information about cats*. The mode can be changed with buttons at the top right corner.  
  
<a href="report page 2-1.png"><img src="images/report page 2-1.png" style="min-width: 300px"></a>  
  
First, the number of dogs that use the smart collar, average daily steps, and average activity minutes of dogs are displayed. Then there is a bar chart that displays dogs' breeds and how many dogs of each breed use the smart collar. As it can be seen from the graph, there is a variety of breeds in the sample, and there is no underrepresented or overrepresented breeds. Similarly, from the donut chart that shows breakdown of dogs by gender, it can be seen that both genders are presented in the sample.  
Similar information can be found about cats.  
  
<a href="report page 2-2.png"><img src="images/report page 2-2.png" style="min-width: 300px"></a>  
  
Slicer for breed  allows a user to search and select a breed that they want to look up. And date slicer allows to filter desired period.
One can also press on one of the breeds in the bar chart, press the button *See details for [breed]* and navigate to a drill-through page that shows: average daily steps, average weight, average age, average activity minutes, and average heartrate for a breed of a dog/cat. The button at the upper left allows to navigate back to the Pets page.  
  
<a href="drill through.png"><img src="images/drill through.png" style="min-width: 300px"></a>  
  
The third page contains information about owners of pets. First, the number of families that use the smart collars for their pets, average number of pets owned in a family, median annual household income, and median expenses on a pet in the sample are displayed. Next, there is a bubble map that shows average expenses on a pet for every state in the US: the bigger the size of the a bubble, the higher the average expenses in a state are. In addition, there is a scatter plot that shows that there is a small positive corellation between annual household income and annual expenses on a pet: the higher the income, the higher the expenses on a pet are. A user can search and select a city or state in a hierarchical slicer, filter a range for household income, select households by the number of pets they own.  
   
<a href="report page 3.png"><img src="images/report page 3.png" style="min-width: 300px"></a>  

#### Conclusion  
In this project I visualized data in Power BI so that management team could quickly assess the information and make business decision based on the data.  
Main insights:
- As it can be seen from the report, there are significant differences in activity of dogs and cats with dogs having higher number of daily steps and activity minutes.
- Tracked by the smart collar, dogs's daily steps increased in the first year and in the two consecutive years, while for cats their activity didn't change.
- Device for dogs has a high rating, and it is recommended in 90% of the cases. On the other hand, device for cats has a low rating, and it is not recommended in the 90% of the cases.
- So the smart device for cats need to be revised, either the collar has to be changed, or another metrics, not daily steps or activity minutes, for cats needs to be used. 
