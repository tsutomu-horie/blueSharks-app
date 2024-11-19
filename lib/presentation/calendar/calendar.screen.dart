import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controllers/calendar.controller.dart';

class CalendarScreen extends StatelessWidget {
  final CalendarScreenController controller = CalendarScreenController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Flexible(
              child: InkWell(
                onTap: () {
                  showFilterBottomSheet(controller, context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: BorderColor.secondary)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12.w,
                      ),
                      SvgPicture.asset(
                        "assets/vectors/ic_calendar-edit.svg",
                        width: 20.w,
                        height: 20.h,
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          child: Obx(() {
                            return CustomTextView(
                              controller.selectedYear.value,
                              type: TDSFontType.bodyTextMedium,
                              color: TextColor.primary,
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20.w,
                      ),
                      SizedBox(
                        width: 12.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
            PopupMenuButton<CalendarView>(
              color: Colors.white,
              position: PopupMenuPosition.under,
              icon: SvgPicture.asset("assets/vectors/ic_calendar.svg"),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: CalendarView.day,
                  child: Text('Day'),
                ),
                const PopupMenuItem(
                  value: CalendarView.week,
                  child: Text('Week'),
                ),
                const PopupMenuItem(
                  value: CalendarView.month,
                  child: Text('Month'),
                ),
              ],
              onSelected: (value) {
                controller.onChangeCalendar(value);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return SfCalendar(
                key: Key("${controller.calendarView.value}"),
                view: controller.calendarView.value,
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment, // Proper display mode
                  showAgenda: false,
                  agendaItemHeight: 50, // Adjust the height for each agenda item
                ),
                headerStyle: CalendarHeaderStyle(
                  backgroundColor: BrandColor.surface,
                  textStyle: TextStyle(
                    color: BrandColor.main, // Text color
                    fontSize: 14.sp, // Text size
                    fontWeight: FontWeight.w500,
                  ),
                ),
                appointmentBuilder: (context, details) {
                  final Appointment appointment = details.appointments.first;

                  return Container(
                    decoration: BoxDecoration(
                      color: BrandColor.main,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    // padding: const EdgeInsets.all(4), // Adjust padding as needed
                    child: Center(
                      child: Text(
                        appointment.subject,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white, // Set the text color
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2, // Ensure the text has a maximum of 2 lines
                        overflow: TextOverflow.ellipsis, // Add ellipsis if the text exceeds 2 lines
                      ),
                    ),
                  );
                },
                todayHighlightColor: BrandColor.main,
                onViewChanged: (ViewChangedDetails details) {
                  // Get the visible date range from the calendar
                  final DateTime minDate = details.visibleDates.first;
                  final DateTime maxDate = details.visibleDates.last;

                  controller.changeDisplay(minDate, maxDate);
                  // Fetch events based on the visible date range
                  // controller.onChangeFilter(minDate, maxDate);
                },
                dataSource: EventDataSource(controller.publicEvents),
              );
            }),
          ),
        ],
      ),
    );
  }

  void showFilterBottomSheet( CalendarScreenController calendarController, BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          height: 284.h, // Fixed height for the bottom sheet
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Center(
                  child: Container(
                width: 48.w,
                height: 4.w,
                color: BorderColor.primary,
              )),
              SizedBox(height: 16.h),
              Expanded(
                // Wrap ListView with Expanded to avoid unbounded height
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarController.filterEvent.length,
                  itemBuilder: (context, index) {
                    final item = calendarController.filterEvent[index];
                    return Column(
                      children: [
                        SizedBox(
                          height: 44.h,
                          child: Row(
                            children: [
                              Flexible(
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomTextView(
                                            item,
                                            type: TDSFontType.labelLarge,
                                          ),
                                          SizedBox(
                                            height: 32.h,
                                            child: OutlinedButton(
                                                onPressed: () {
                                                  controller
                                                      .onSelectFilter(item);
                                                  // controller.onChangeFilter(controller.minDate.value, controller.maxDate.value);
                                                  Get.back();
                                                },
                                                child: CustomTextView(
                                                  LocaleKeys.select.tr,
                                                  type: TDSFontType.labelLarge,
                                                  color: BrandColor.main,
                                                )),
                                          )
                                        ],
                                      ))),
                            ],
                          ),
                        ),
                        if (index != calendarController.filterEvent.length - 1)
                          Container(
                            height: 1.h,
                            color: BorderColor.primary,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<CalendarEvent> source) {
    appointments = source.map((event) {
      return Appointment(
        startTime: event.start,
        endTime: event.end,
        subject: event.title,
        notes: event.description,
        color: Colors.blue, // Customize the color of the event
      );
    }).toList();
  }
}
